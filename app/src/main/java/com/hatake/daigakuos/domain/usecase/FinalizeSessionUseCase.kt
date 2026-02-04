package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.NodeDao
import com.hatake.daigakuos.data.local.dao.SessionDao
import com.hatake.daigakuos.data.local.dao.SettingsDao
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.NodeType
import com.hatake.daigakuos.data.local.entity.SettingsEntity
import java.util.UUID
import javax.inject.Inject

class FinalizeSessionUseCase @Inject constructor(
    private val sessionDao: SessionDao,
    private val settingsDao: SettingsDao,
    private val nodeDao: NodeDao,
    private val projectDao: com.hatake.daigakuos.data.local.dao.ProjectDao,
    private val pointsCalculator: PointsCalculator,
    private val updateDailyAggregationUseCase: UpdateDailyAggregationUseCase
) {
    suspend operator fun invoke(
        sessionId: String,
        selectedNodeId: String?,
        newNodeTitle: String?,
        newNodeType: NodeType?,
        selfReportMin: Int,
        focus: Int
    ) {
        val endAt = System.currentTimeMillis()
        val finalizedAt = System.currentTimeMillis()
        
        // 1. Resolve Node
        var finalNodeId = selectedNodeId
        
        if (finalNodeId == null && newNodeTitle != null && newNodeType != null) {
            val defaultProject = projectDao.findDefaultProject()
            val projectId = defaultProject?.id ?: "inbox"
            
            val newNode = NodeEntity(
                id = UUID.randomUUID().toString(),
                projectId = projectId,
                title = newNodeTitle,
                type = newNodeType.name,
                status = "DONE",
                updatedAt = finalizedAt
            )
            nodeDao.insertNode(newNode)
            finalNodeId = newNode.id
        }

        // 2. Fetch Session & Settings
        val session = sessionDao.getSessionById(sessionId) ?: return
        val onCampus = session.onCampus
        
        var settings = settingsDao.getSettings()
        if (settings == null) {
            settings = SettingsEntity()
            settingsDao.insertSettings(settings)
        }

        // 3. Calc Points
        val points = pointsCalculator.computePoints(
            selfReportMin = selfReportMin,
            focus = focus,
            onCampus = onCampus,
            campusBaseMultiplier = settings.campusBaseMultiplier,
            streakMultiplier = 1.0
        )

        // 4. Update Session
        val updatedSession = session.copy(
            nodeId = finalNodeId ?: session.nodeId,
            endAt = endAt,
            selfReportMin = selfReportMin,
            focus = focus,
            points = points,
            finalizedAt = finalizedAt
        )
        sessionDao.updateSession(updatedSession)
        
        // 5. Update Aggregation (using centralized use case)
        updateDailyAggregationUseCase(finalNodeId, points, selfReportMin)
        
        // 6. Mark Node as Updated
        if (finalNodeId != null) {
            nodeDao.markDone(finalNodeId, finalizedAt)
        }
    }
}
