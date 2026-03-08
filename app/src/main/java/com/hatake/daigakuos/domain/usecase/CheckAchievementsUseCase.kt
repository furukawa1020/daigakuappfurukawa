package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.AchievementDao
import com.hatake.daigakuos.data.local.entity.AchievementEntity
import com.hatake.daigakuos.data.local.entity.SessionEntity
import java.util.Calendar
import javax.inject.Inject

class CheckAchievementsUseCase @Inject constructor(
    private val achievementDao: AchievementDao
) {
    /**
     * Checks if any new achievements should be unlocked based on the completed session
     * and current stats.
     * Returns a list of newly unlocked achievement IDs.
     */
    suspend operator fun invoke(
        session: SessionEntity,
        streak: Int,
        totalSessionsCount: Int,
        totalPoints: Double,
        isOnCampus: Boolean
    ): List<String> {
        val newlyUnlocked = mutableListOf<String>()

        // Helper to evaluate and potentially unlock
        suspend fun evaluate(id: String, condition: Boolean) {
            if (condition) {
                // Returns row ID if inserted, or -1 if it was ignored (already exists)
                val rowId = achievementDao.unlockAchievement(AchievementEntity(id = id))
                if (rowId != -1L) {
                    newlyUnlocked.add(id)
                }
            }
        }

        // 1. firstSession
        evaluate("first_session", totalSessionsCount == 1)

        // 2. Streaks
        evaluate("three_day_streak", streak >= 3)
        evaluate("seven_day_streak", streak >= 7)

        // 3. Quick Win (5 min session)
        evaluate("quick_win", (session.selfReportMin ?: 0) in 1..5)

        // 4. Hyper Focus (60+ min session)
        evaluate("hyper_focus", (session.selfReportMin ?: 0) >= 60)

        // 5. Home Guardian (Focused at home)
        evaluate("home_guardian", !isOnCampus && (session.selfReportMin ?: 0) >= 25)

        // 6. Time-based (Night Owl / Early Bird)
        val calendar = Calendar.getInstance().apply { timeInMillis = session.startAt }
        val hour = calendar.get(Calendar.HOUR_OF_DAY)
        
        // Early Bird: Started between 4 AM and 8 AM
        evaluate("early_bird", hour in 4..8)
        
        // Night Owl: Started between 10 PM and 3 AM
        evaluate("night_owl", hour >= 22 || hour <= 3)

        // 7. Total Time 10 Hours (Approximated via points/count here or can be passed differently)
        // Since points = 10 per minute approx, 10 hours = 600 mins = 6000 points.
        evaluate("total_time_10_hours", totalPoints >= 6000.0)

        return newlyUnlocked
    }
}
