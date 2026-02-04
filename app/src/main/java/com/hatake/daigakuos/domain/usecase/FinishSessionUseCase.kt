package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.SessionDao
import com.hatake.daigakuos.data.local.dao.SettingsDao
import com.hatake.daigakuos.data.local.entity.SettingsEntity
import javax.inject.Inject

class FinishSessionUseCase @Inject constructor(
    private val sessionDao: SessionDao,
    private val settingsDao: SettingsDao,
    private val pointsCalculator: PointsCalculator,
    private val updateDailyAggregationUseCase: UpdateDailyAggregationUseCase
) {
    suspend operator fun invoke(
        sessionId: String,
        selfReportMin: Int,
        focus: Int
    ) {
        val endAt = System.currentTimeMillis()
        
        // 1. Fetch Session Context
        val session = sessionDao.getSessionById(sessionId)
        val onCampus = session?.onCampus ?: false
        val nodeId = session?.nodeId
        val session = sessionDao.getSessionById(sessionId) 
            ?: throw IllegalStateException("Session with id $sessionId not found")
        val onCampus = session.onCampus
        val nodeId = session.nodeId
        
        // 2. Fetch Node to determine Type
        val node = if (nodeId != null) nodeDao.getNodeById(nodeId) else null

        // 2. Settings (or Default)
        var settings = settingsDao.getSettings()
        if (settings == null) {
            settings = SettingsEntity()
            settingsDao.insertSettings(settings)
        }

        // 3. Calculate Points
        val points = pointsCalculator.computePoints(
            selfReportMin = selfReportMin,
            focus = focus,
            onCampus = onCampus,
            campusBaseMultiplier = settings.campusBaseMultiplier,
            streakMultiplier = 1.0
        )

        // 4. Update Session
        sessionDao.endSession(sessionId, endAt, selfReportMin, focus, points)

        // 5. Update Daily Aggregation (using centralized use case)
        updateDailyAggregationUseCase(nodeId, points, selfReportMin)
        // 5. Update DailyAgg (using atomic updates to prevent race conditions)
        val yyyymmdd = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date()).toInt()
        
        // Use atomic updates based on node type
        // If the row doesn't exist (returns 0), insert it and retry
        val updateSuccessful = if (node != null) {
            try {
                when (NodeType.valueOf(node.type)) {
                    NodeType.STUDY -> aggDao.addStudyPoints(yyyymmdd, points, selfReportMin)
                    NodeType.RESEARCH -> aggDao.addResearchPoints(yyyymmdd, points, selfReportMin)
                    NodeType.MAKE -> aggDao.addMakePoints(yyyymmdd, points, selfReportMin)
                    NodeType.ADMIN -> aggDao.addAdminPoints(yyyymmdd, points, selfReportMin)
                }
            } catch (e: Exception) {
                // Unknown type, maybe legacy or string mismatch. Add to Study default.
                aggDao.addStudyPoints(yyyymmdd, points, selfReportMin)
            }
        } else {
            // No Node (Ad-hoc), default to Admin (Task handling)
            aggDao.addAdminPoints(yyyymmdd, points, selfReportMin)
        }
        
        // If atomic update failed (row didn't exist), insert and retry
        if (updateSuccessful == 0) {
            aggDao.upsertDailyAgg(DailyAggEntity(yyyymmdd = yyyymmdd))
            // Retry the update
            if (node != null) {
                try {
                    when (NodeType.valueOf(node.type)) {
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
        
        // If Node exists, mark done? 
        // Spec: Session doesn't autocompile Node. User marks 'DONE' separately?
        // Or if it was a "Do this task" flow, maybe?
        // Current UI implies "Start -> Timer -> Complete". 
        // If it's a "Task", usually we want to mark it done if user says so.
        // But the dialog just asks for Time/Focus.
        // We'll leave Node status as is (User can mark done in Tree or List).
    }
}
