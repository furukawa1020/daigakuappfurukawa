package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.domain.logic.RecommendationEngine
import com.hatake.daigakuos.domain.repository.NodeRepository
import com.hatake.daigakuos.domain.repository.StatsRepository
import com.hatake.daigakuos.domain.repository.UserContextRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class GetRecommendationUseCase @Inject constructor(
    private val nodeRepository: NodeRepository,
    private val statsRepository: StatsRepository,
    private val userContextRepository: UserContextRepository,
    private val recommendationEngine: RecommendationEngine
) {
    suspend operator fun invoke(): NodeEntity? {
        // 1. Get Context
        val isOnCampus = userContextRepository.isOnCampus.first()
        val recentRecovery = statsRepository.getRecentRecoveryCount()
        val streak = statsRepository.getStreak()
        val todayTypes = statsRepository.getTodayCompletedTypes()

        // 2. Get Candidates (Use Flow or suspending function depending on Repo)
        // Since getActiveNodes returns Flow, we take the first emission
        val candidates = nodeRepository.getActiveNodes().first()
        
        if (candidates.isEmpty()) return null

        // 3. Rank
        // RecommendationEngine expects a List, so we pass it directly
        val ranked = recommendationEngine.rankNodes(
            nodes = candidates,
            context = RecommendationEngine.Context(
                isOnCampus = isOnCampus,
                recentRecoveryCount = recentRecovery,
                currentStreakDays = streak,
                completedNodeTypesToday = todayTypes
            )
        )

        return ranked.firstOrNull()
    }
}
