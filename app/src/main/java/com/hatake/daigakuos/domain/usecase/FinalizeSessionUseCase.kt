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
        val session = sessionDao.getSessionById(sessionId) 
            ?: throw IllegalStateException("Session with id $sessionId not found")
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
        // 5. Update Agg (using atomic updates to prevent race conditions)
        val yyyymmdd = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date()).toInt()
        
        // Check Node Type
        val nodeTypeStr = if (finalNodeId != null) {
            nodeDao.getNodeById(finalNodeId)?.type
        } else null
        
        // Use atomic updates based on node type
        // If the row doesn't exist (returns 0), insert it and retry
        val updateSuccessful = if (nodeTypeStr != null) {
             try {
                when (NodeType.valueOf(nodeTypeStr)) {
                    NodeType.STUDY -> aggDao.addStudyPoints(yyyymmdd, points, selfReportMin)
                    NodeType.RESEARCH -> aggDao.addResearchPoints(yyyymmdd, points, selfReportMin)
                    NodeType.MAKE -> aggDao.addMakePoints(yyyymmdd, points, selfReportMin)
                    NodeType.ADMIN -> aggDao.addAdminPoints(yyyymmdd, points, selfReportMin)
                }
            } catch (e: Exception) { 
                // Unknown type, default to Study
                aggDao.addStudyPoints(yyyymmdd, points, selfReportMin)
            }
        } else {
             // Unspecified points -> Admin
             aggDao.addAdminPoints(yyyymmdd, points, selfReportMin)
        }
        
        // If atomic update failed (row didn't exist), insert and retry
        if (updateSuccessful == 0) {
            aggDao.upsertDailyAgg(DailyAggEntity(yyyymmdd = yyyymmdd))
            // Retry the update
            if (nodeTypeStr != null) {
                try {
                    when (NodeType.valueOf(nodeTypeStr)) {
                        NodeType.STUDY -> aggDao.addStudyPoints(yyyymmdd, points, selfReportMin)
                        NodeType.RESEARCH -> aggDao.addResearchPoints(yyyymmdd, points, selfReportMin)
                        NodeType.MAKE -> aggDao.addMakePoints(yyyymmdd, points, selfReportMin)
                        NodeType.ADMIN -> aggDao.addAdminPoints(yyyymmdd, points, selfReportMin)
                    }
                } catch (e: Exception) { 
                    aggDao.addStudyPoints(yyyymmdd, points, selfReportMin)
                }
            } else {
                aggDao.addAdminPoints(yyyymmdd, points, selfReportMin)
            }
        }
        
        // 6. Mark Node as Updated
        if (finalNodeId != null) {
            nodeDao.markDone(finalNodeId, finalizedAt)
        }
    }
}
