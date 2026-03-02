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
        val todayStr = java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.BASIC_ISO_DATE)
        val yyyymmdd = todayStr.toInt()
        val agg = aggDao.getAgg(yyyymmdd) ?: return emptyList()
        val types = mutableListOf<NodeType>()
        if (agg.pointsStudy > 0) types.add(NodeType.STUDY)
        if (agg.pointsResearch > 0) types.add(NodeType.RESEARCH)
        if (agg.pointsMake > 0) types.add(NodeType.MAKE)
        if (agg.pointsAdmin > 0) types.add(NodeType.ADMIN)
        return types
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

    override suspend fun addPointsFromCompletedNode(nodeType: NodeType, points: Double, minutes: Int) {
        val todayStr = java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.BASIC_ISO_DATE)
        val yyyymmdd = todayStr.toInt()
        
        val updated = when(nodeType) {
            NodeType.STUDY -> aggDao.addStudyPoints(yyyymmdd, points, minutes)
            NodeType.RESEARCH -> aggDao.addResearchPoints(yyyymmdd, points, minutes)
            NodeType.MAKE -> aggDao.addMakePoints(yyyymmdd, points, minutes)
            NodeType.ADMIN -> aggDao.addAdminPoints(yyyymmdd, points, minutes)
        }
        
        if (updated == 0) {
            val newAgg = com.hatake.daigakuos.data.local.entity.DailyAggEntity(yyyymmdd = yyyymmdd)
            aggDao.upsertDailyAgg(newAgg)
            when(nodeType) {
                NodeType.STUDY -> aggDao.addStudyPoints(yyyymmdd, points, minutes)
                NodeType.RESEARCH -> aggDao.addResearchPoints(yyyymmdd, points, minutes)
                NodeType.MAKE -> aggDao.addMakePoints(yyyymmdd, points, minutes)
                NodeType.ADMIN -> aggDao.addAdminPoints(yyyymmdd, points, minutes)
            }
        }
    }
}
