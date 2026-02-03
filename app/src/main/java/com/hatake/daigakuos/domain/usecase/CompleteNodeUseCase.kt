package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.domain.logic.PointCalculator
import com.hatake.daigakuos.domain.repository.NodeRepository
import com.hatake.daigakuos.domain.repository.StatsRepository
import javax.inject.Inject

class CompleteNodeUseCase @Inject constructor(
    private val nodeRepository: NodeRepository,
    private val statsRepository: StatsRepository,
    private val pointCalculator: PointCalculator
) {
    suspend operator fun invoke(
        node: NodeEntity,
        actualMinutes: Int,
        focusLevel: Int,
        isOnCampus: Boolean
    ) {
        // 1. Gather Context Data
        val todayTypes = statsRepository.getTodayCompletedTypes()
        // Add current node type to the list for calculation (simulating it being part of today)
        val updatedTypes = todayTypes + node.type
        
        val recentRecovery = statsRepository.getRecentRecoveryCount()
        val streak = statsRepository.getStreak()

        // 2. Calculate Points
        val result = pointCalculator.calculate(
            PointCalculator.Inputs(
                completedNodeTypesToday = updatedTypes,
                isOnCampus = isOnCampus,
                focusLevel = focusLevel,
                estimateMinutes = node.estimateMinutes,
                recentRecoveryCount = recentRecovery,
                currentStreakDays = streak
            )
        )

        // 3. Persist
        // The repository handle creation of NodeEvent with the calculated point info
        // We might need to pass the calculation result to the repo
        // For now, let's assume the repo helper does the heavy lifting or we construct the Entity here.
        // In clean architecture, UseCase often constructs the entity or DTO.
        
        nodeRepository.completeNode(
            nodeId = node.id,
            actualMinutes = actualMinutes,
            focusLevel = focusLevel,
            isOnCampus = isOnCampus,
            streakDays = streak 
            // We would actually pass 'result.totalPoints' here if the Repo supports it, 
            // but the interface currently doesn't have it.
            // Let's assume we update the Repo interface or implementation later to accept the explicit points.
        )
    }
}
