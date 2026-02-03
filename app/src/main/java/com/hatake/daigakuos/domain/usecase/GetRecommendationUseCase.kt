package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.entity.Mode
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.ProjectType
import com.hatake.daigakuos.domain.repository.NodeRepository
import javax.inject.Inject

class GetRecommendationUseCase @Inject constructor(
    private val nodeRepository: NodeRepository
) {
    /**
     * @param currentMode User's current mode (Default / Creative / Recovery)
     */
    suspend operator fun invoke(currentMode: Mode): List<NodeEntity> {
        val allTodos = nodeRepository.getTodoNodes()
        
        if (allTodos.isEmpty()) return emptyList()

        // Filter and Sort Logic
        // 9.2 Recommendation Output Specification
        // - Always 2-3 items max.
        // - Default: At least 2 STUDY.
        // - Creative Mode: RESEARCH/MAKE prioritized.
        
        val studyNodes = allTodos.filter { it.type == ProjectType.STUDY }
        val researchNodes = allTodos.filter { it.type == ProjectType.RESEARCH }
        val makeNodes = allTodos.filter { it.type == ProjectType.MAKE }
        val adminNodes = allTodos.filter { it.type == ProjectType.ADMIN } // Usually low priority unless deadline

        val recommended = mutableListOf<NodeEntity>()

        when (currentMode) {
            Mode.DEFAULT -> {
                // Pick 2 STUDY
                recommended.addAll(studyNodes.take(2))
                
                // Maybe pick 1 other (Research or Make) if available
                if (recommended.size < 3) {
                    val others = (researchNodes + makeNodes).shuffled()
                    others.firstOrNull()?.let { recommended.add(it) }
                }
            }
            Mode.CREATIVE -> {
                // Pick Research/Make first
                val creative = (researchNodes + makeNodes).shuffled()
                recommended.addAll(creative.take(2))
                
                // Add one Study if space
                if (recommended.size < 3) {
                    studyNodes.firstOrNull()?.let { recommended.add(it) }
                }
            }
            Mode.RECOVERY -> {
                // Recovery Mode Logic
                // Suggest light tasks or breakdown tasks?
                // For now, maybe just Admin or very short tasks
                val shortTasks = allTodos.filter { it.estimateMinutes <= 15 }
                recommended.addAll(shortTasks.take(3))
            }
        }

        // Fallback: If empty, fill with whatever is available
        if (recommended.isEmpty()) {
            recommended.addAll(allTodos.take(3))
        }

        return recommended.take(3)
    }
}
