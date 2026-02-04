package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.AggDao
import com.hatake.daigakuos.data.local.dao.NodeDao
import com.hatake.daigakuos.data.local.dao.SessionDao
import com.hatake.daigakuos.data.local.dao.SettingsDao
import com.hatake.daigakuos.data.local.entity.DailyAggEntity
import com.hatake.daigakuos.data.local.entity.NodeType
import com.hatake.daigakuos.data.local.entity.SettingsEntity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject

class FinishSessionUseCase @Inject constructor(
    private val sessionDao: SessionDao,
    private val aggDao: AggDao,
    private val settingsDao: SettingsDao,
    private val nodeDao: NodeDao, // Added
    private val pointsCalculator: PointsCalculator
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
        
        // 2. Fetch Node to determine Type
        val node = if (nodeId != null) nodeDao.getNodeById(nodeId) else null

        // 3. Settings (or Default)
        var settings = settingsDao.getSettings()
        if (settings == null) {
            settings = SettingsEntity()
            settingsDao.insertSettings(settings)
        }

        // Mock Recency/Streak for MVP
        val streakMul = 1.0 

        val points = pointsCalculator.computePoints(
            selfReportMin = selfReportMin,
            focus = focus,
            onCampus = onCampus,
            campusBaseMultiplier = settings.campusBaseMultiplier,
            streakMultiplier = streakMul
        )

        // 4. Update Session
        sessionDao.endSession(sessionId, endAt, selfReportMin, focus, points)

        // 5. Update DailyAgg
        val yyyymmdd = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date()).toInt()
        val currentAgg = aggDao.getAgg(yyyymmdd) ?: DailyAggEntity(yyyymmdd = yyyymmdd)
        
        // Update Agg fields based on NodeType
        // If node is null (Ad-hoc session?), attribute to Study or distribute? 
        // Let's assume Study/Admin mix or just leave fields 0 and only update Total.
        // But for "User Spec", Research/Make/Study balance is key.
        
        var pStudy = currentAgg.pointsStudy
        var pResearch = currentAgg.pointsResearch
        var pMake = currentAgg.pointsMake
        var pAdmin = currentAgg.pointsAdmin
        
        if (node != null) {
            try {
                when (NodeType.valueOf(node.type)) {
                    NodeType.STUDY -> pStudy += points
                    NodeType.RESEARCH -> pResearch += points
                    NodeType.MAKE -> pMake += points
                    NodeType.ADMIN -> pAdmin += points
                }
            } catch (e: Exception) {
                // Unknown type, maybe legacy or string mismatch. Add to Study default.
                pStudy += points
            }
        } else {
            // No Node (Ad-hoc), default to Admin or Study? 
            // Let's assume Admin (Task handling)
            pAdmin += points
        }
        
        val newAgg = currentAgg.copy(
            pointsTotal = currentAgg.pointsTotal + points,
            countDone = currentAgg.countDone + 1,
            minutesSelfReport = currentAgg.minutesSelfReport + selfReportMin,
            pointsStudy = pStudy,
            pointsResearch = pResearch,
            pointsMake = pMake,
            pointsAdmin = pAdmin
        )
        aggDao.upsertDailyAgg(newAgg)
        
        // If Node exists, mark done? 
        // Spec: Session doesn't autocompile Node. User marks 'DONE' separately?
        // Or if it was a "Do this task" flow, maybe?
        // Current UI implies "Start -> Timer -> Complete". 
        // If it's a "Task", usually we want to mark it done if user says so.
        // But the dialog just asks for Time/Focus.
        // We'll leave Node status as is (User can mark done in Tree or List).
    }
}
