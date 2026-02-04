package com.hatake.daigakuos.data.repository

import com.hatake.daigakuos.data.local.dao.EventDao
import com.hatake.daigakuos.data.local.dao.DailyMetricDao
import com.hatake.daigakuos.data.local.entity.ProjectType
import com.hatake.daigakuos.domain.repository.StatsRepository
import javax.inject.Inject
import javax.inject.Singleton
import java.util.Calendar
import kotlinx.coroutines.flow.map

@Singleton
class StatsRepositoryImpl @Inject constructor(
    private val eventDao: EventDao,
    private val dailyMetricDao: DailyMetricDao,
    private val userContextRepository: com.hatake.daigakuos.domain.repository.UserContextRepository
) : StatsRepository {

    override suspend fun getTodayCompletedTypes(): List<ProjectType> {
       return emptyList() 
    }

    override suspend fun getRecentRecoveryCount(): Int {
        val threeHoursAgo = System.currentTimeMillis() - (3 * 60 * 60 * 1000)
        return eventDao.getRecentRecoveryCount(threeHoursAgo)
    }

    override suspend fun getStreak(): Int {
        return 0
    }

    override fun getTotalPoints(): kotlinx.coroutines.flow.Flow<Float> {
        return eventDao.getTotalPoints().map { it ?: 0f }
    }

    override suspend fun logSession(nodeId: Long, durationMillis: Long, points: Float) {
        val isOnCampus = userContextRepository.isOnCampus.value
        val actualMinutes = (durationMillis / 1000 / 60).toInt().coerceAtLeast(1)
        
        val event = com.hatake.daigakuos.data.local.entity.NodeEventEntity(
            nodeId = nodeId,
            timestamp = System.currentTimeMillis(),
            actualMinutes = actualMinutes,
            focusLevel = 3, // Default normal focus
            isOnCampus = isOnCampus,
            diversityScore = 1.0f, // MVP default
            recoveryMultiplier = 1.0f, // MVP default
            finalPoints = points
        )
        try {
            eventDao.insertNodeEvent(event)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
