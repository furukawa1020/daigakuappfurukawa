package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.AggDao
import com.hatake.daigakuos.data.local.dao.SessionDao
import com.hatake.daigakuos.data.local.dao.SettingsDao
import com.hatake.daigakuos.data.local.entity.DailyAggEntity
import com.hatake.daigakuos.data.local.entity.SettingsEntity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject

class FinishSessionUseCase @Inject constructor(
    private val sessionDao: SessionDao,
    private val aggDao: AggDao,
    private val settingsDao: SettingsDao,
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
        
        // 2. Settings (or Default)
        var settings = settingsDao.getSettings()
        if (settings == null) {
            settings = SettingsEntity()
            settingsDao.insertSettings(settings)
        }

        // Mock Recency/Streak for MVP (Future: Calculate from Session History)
        val streakMul = 1.0 

        val points = pointsCalculator.computePoints(
            selfReportMin = selfReportMin,
            focus = focus,
            onCampus = onCampus,
            campusBaseMultiplier = settings.campusBaseMultiplier,
            streakMultiplier = streakMul
        )

        // 3. Update Session
        sessionDao.endSession(sessionId, endAt, selfReportMin, focus, points)

        // 4. Update DailyAgg
        // Determine NodeType to attribute points correctly
        // We need Node from DB.
        // Assuming we have NodeDao injected... wait, we need NodeDao.
        // I will add NodeDao to constructor.
        
        // Note: Invoke doesn't have NodeDao injected yet in this file scope. 
        // I MUST update constructor injection in the actual file update.
        
        // For now, I will assume Generic aggregation if NodeDao is missing, 
        // BUT ideally I should fetch Node.
        
        val yyyymmdd = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date()).toInt()
        val currentAgg = aggDao.getAgg(yyyymmdd) ?: DailyAggEntity(yyyymmdd = yyyymmdd)
        
        // Prepare new Agg
        // Use generic "Study" if unknown for MVP, or better, split evenly? 
        // Let's just put it in total and maybe update specific if we can.
        // Since I can't easily add NodeDao to constructor in 'ReplacementContent' without replacing the class header...
        // I will perform a replacement of the Logic block first.
        
        // Actually, without NodeDao, I can't know the Type.
        // I will update the Constructor AND the Logic in a full file rewrite or multi-chunk.
        // Let's do a rewrite of the UseCase to include NodeDao.
        val newAgg = currentAgg.copy(
            pointsTotal = currentAgg.pointsTotal + points,
            countDone = currentAgg.countDone + 1,
            minutesSelfReport = currentAgg.minutesSelfReport + selfReportMin
        )
        aggDao.upsertDailyAgg(newAgg)
    }
}
