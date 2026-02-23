package com.hatake.daigakuos.data.repository

import com.hatake.daigakuos.data.local.dao.SessionDao
import com.hatake.daigakuos.data.local.dao.AggDao
import com.hatake.daigakuos.data.local.entity.NodeType
import com.hatake.daigakuos.domain.repository.StatsRepository
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf

@Singleton
class StatsRepositoryImpl @Inject constructor(
    private val sessionDao: SessionDao,
    private val aggDao: AggDao,
    private val userContextRepository: com.hatake.daigakuos.domain.repository.UserContextRepository
) : StatsRepository {

    override suspend fun getTodayCompletedTypes(): List<NodeType> {
       return emptyList() 
    }

    override suspend fun getRecentRecoveryCount(): Int {
        // Fallback stub since EventDao is removed
        return 0
    }

    override suspend fun getStreak(): Int {
        return 0
    }

    override fun getTotalPoints(): Flow<Float> {
        // Fallback stub since EventDao is removed
        return flowOf(0f)
    }

    override suspend fun logSession(nodeId: Long, durationMillis: Long, points: Float) {
        val isOnCampus = userContextRepository.isOnCampus.value
        val actualMinutes = (durationMillis / 1000 / 60).toInt().coerceAtLeast(1)
        
        // MVP Logging - Currently stubbed to allow compilation.
        // Full session logging logic is handled by StartSessionUseCase / UpsertNodeUseCase
    }
}
