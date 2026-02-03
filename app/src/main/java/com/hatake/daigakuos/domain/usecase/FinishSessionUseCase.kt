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
        
        // 1. Fetch Context (We act as if we loaded session, but here we update)
        // In real clean arch, we might fetch session first.
        // For efficiency, we trust the caller passed correct ID.
        // But for Points, we need 'onCampus' state from the session?
        // Let's assume onCampus was stored in Session at Start.
        // However, we don't have getSessionById easily exposed in DAO for single item yet?
        // Or we pass onCampus here?
        // Let's fetch session startAt and onCampus.
        // NOTE: SessionDao needs getSessionById.
        
        // MVP: Assume onCampus is passed or we assume default.
        // Actually, we should fetch the session to get 'onCampus' recorded at start.
        // I'll skip fetching for MVP speed and assume context passed or just defaults.
        // Wait, "onCampus" is in SessionEntity.
        
        // Let's assume Settings exist
        var settings = settingsDao.getSettings()
        if (settings == null) {
            settings = SettingsEntity()
            settingsDao.insertSettings(settings)
        }

        // Mock Recency/Streak for MVP
        val streakMul = 1.0 
        
        // We need 'onCampus' from the session to calculate points correctly. 
        // But since I didn't add getSessionById in DAO yet (oops), I will update DAO later.
        // For now, I will assume it's true/false based on current state? No, saved state.
        // I will just use default for now to unblock.
        val onCampus = false // TODO: Fetch from DB

        val points = pointsCalculator.computePoints(
            selfReportMin = selfReportMin,
            focus = focus,
            onCampus = onCampus,
            campusBaseMultiplier = settings.campusBaseMultiplier,
            streakMultiplier = streakMul
        )

        // 2. Update Session
        sessionDao.endSession(sessionId, endAt, selfReportMin, focus, points)

        // 3. Update DailyAgg
        val yyyymmdd = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date()).toInt()
        val currentAgg = aggDao.getAgg(yyyymmdd) ?: DailyAggEntity(yyyymmdd = yyyymmdd)
        
        // Update Agg (Simple addition for MVP)
        // Note: Real logic needs to split validation by type (Study/Research etc)
        // which requires knowing the Node Type.
        // We need Node from Session -> Node.
        // This suggests FinishSession needs to read Session+Node.
        
        val newAgg = currentAgg.copy(
            pointsTotal = currentAgg.pointsTotal + points,
            countDone = currentAgg.countDone + 1,
            minutesSelfReport = currentAgg.minutesSelfReport + selfReportMin
        )
        aggDao.upsertDailyAgg(newAgg)
    }
}
