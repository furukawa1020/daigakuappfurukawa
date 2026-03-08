package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.AggDao
import java.util.Calendar
import javax.inject.Inject

/**
 * Computes the current consecutive-day focus streak.
 * A streak counts days (in yyyymmdd format) where countDone > 0
 * going backwards from yesterday (or today if already completed).
 */
class GetStreakUseCase @Inject constructor(
    private val aggDao: AggDao
) {
    suspend operator fun invoke(): Int {
        val activeDays = aggDao.getActiveDaysDesc()
        if (activeDays.isEmpty()) return 0

        val todayKey = todayYyyymmdd()
        var streak = 0
        var expected = todayKey

        for (entry in activeDays) {
            if (entry.yyyymmdd == expected) {
                streak++
                expected = previousDay(expected)
            } else if (entry.yyyymmdd < expected) {
                // Missed a day - check if we missed today only
                if (expected == todayKey) {
                    // Today not done yet - start counting from yesterday
                    expected = previousDay(todayKey)
                    if (entry.yyyymmdd == expected) {
                        streak++
                        expected = previousDay(expected)
                    } else {
                        break
                    }
                } else {
                    break
                }
            }
        }

        return streak
    }

    private fun todayYyyymmdd(): Int {
        val c = Calendar.getInstance()
        val y = c.get(Calendar.YEAR)
        val m = c.get(Calendar.MONTH) + 1
        val d = c.get(Calendar.DAY_OF_MONTH)
        return y * 10000 + m * 100 + d
    }

    private fun previousDay(key: Int): Int {
        val c = Calendar.getInstance()
        val y = key / 10000
        val m = (key / 100) % 100 - 1  // 0-indexed
        val d = key % 100
        c.set(y, m, d)
        c.add(Calendar.DAY_OF_MONTH, -1)
        val ny = c.get(Calendar.YEAR)
        val nm = c.get(Calendar.MONTH) + 1
        val nd = c.get(Calendar.DAY_OF_MONTH)
        return ny * 10000 + nm * 100 + nd
    }
}
