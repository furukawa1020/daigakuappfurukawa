package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.AggDao
import com.hatake.daigakuos.data.local.entity.WeeklyChallengeEntity
import com.hatake.daigakuos.domain.repository.WeeklyChallengeRepository
import kotlinx.coroutines.flow.firstOrNull
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.IsoFields
import javax.inject.Inject

class SyncWeeklyChallengesUseCase @Inject constructor(
    private val repository: WeeklyChallengeRepository,
    private val aggDao: AggDao
) {
    suspend operator fun invoke() {
        val today = LocalDate.now()
        val year = today.get(IsoFields.WEEK_BASED_YEAR)
        val week = today.get(IsoFields.WEEK_OF_WEEK_BASED_YEAR)
        val yearWeek = "$year-W${week.toString().padStart(2, '0')}"

        // Get Monday and Sunday of the current week (ISO-8601)
        val monday = today.with(DayOfWeek.MONDAY)
        val sunday = today.with(DayOfWeek.SUNDAY)
        val dateFormatter = DateTimeFormatter.ofPattern("yyyyMMdd")
        val startInt = monday.format(dateFormatter).toInt()
        val endInt = sunday.format(dateFormatter).toInt()

        val aggs = aggDao.getAggsInRange(startInt, endInt)
        val currentPoints = aggs.sumOf { it.pointsTotal }
        val currentDays = aggs.count { it.pointsTotal > 0 }.toDouble()

        // We observe the flow once to check existing challenges
        val existingChallenges = repository.getChallengesForWeek(yearWeek).firstOrNull() ?: emptyList()

        if (existingChallenges.isEmpty()) {
            // Generate standard generic tasks for this week
            val challenge1 = WeeklyChallengeEntity(
                id = "$yearWeek-TARGET_POINTS",
                yearWeek = yearWeek,
                type = "TARGET_POINTS",
                targetValue = 1000.0,
                currentValue = currentPoints,
                isCompleted = currentPoints >= 1000.0,
                rewardCoins = 100,
                rewardCrystals = 10
            )

            val challenge2 = WeeklyChallengeEntity(
                id = "$yearWeek-ACTIVE_DAYS",
                yearWeek = yearWeek,
                type = "ACTIVE_DAYS",
                targetValue = 5.0,
                currentValue = currentDays,
                isCompleted = currentDays >= 5.0,
                rewardCoins = 50,
                rewardCrystals = 5
            )

            repository.upsertChallenge(challenge1)
            repository.upsertChallenge(challenge2)
        } else {
            // Update existing tasks with latest values
            existingChallenges.forEach { challenge ->
                val newValue = when (challenge.type) {
                    "TARGET_POINTS" -> currentPoints
                    "ACTIVE_DAYS" -> currentDays
                    else -> challenge.currentValue
                }

                if (challenge.currentValue != newValue) {
                    val isCompleted = newValue >= challenge.targetValue
                    repository.updateChallenge(
                        challenge.copy(
                            currentValue = newValue,
                            isCompleted = isCompleted || challenge.isCompleted // Keep completed if it was
                        )
                    )
                }
            }
        }
    }
}
