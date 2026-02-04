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
    }
}
