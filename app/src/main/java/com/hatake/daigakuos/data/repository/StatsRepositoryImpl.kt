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
    private val dailyMetricDao: DailyMetricDao
) : StatsRepository {

    override suspend fun getTodayCompletedTypes(): List<ProjectType> {
       // Simplified: retrieving just types is hard without joining nodes, 
       // so returning empty list for MVP or implementing a complex query later.
       // The DB schema needs a join between NodeEvent and Node to get types.
       return emptyList() 
    }

    override suspend fun getRecentRecoveryCount(): Int {
        val threeHoursAgo = System.currentTimeMillis() - (3 * 60 * 60 * 1000)
        return eventDao.getRecentRecoveryCount(threeHoursAgo)
    }

    override suspend fun getStreak(): Int {
        // Mock implementation for MVP
        return 0
    }

    override fun getTotalPoints(): kotlinx.coroutines.flow.Flow<Float> {
        return eventDao.getTotalPoints().map { it ?: 0f }
    }
}
