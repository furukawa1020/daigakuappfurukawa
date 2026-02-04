package com.hatake.daigakuos.domain.logic

import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.ProjectType
import javax.inject.Inject

class RecommendationEngine @Inject constructor() {

    data class Context(
        val isOnCampus: Boolean,
        val recentRecoveryCount: Int,
        val currentStreakDays: Int,
        val completedNodeTypesToday: List<ProjectType>
    )

    fun rankNodes(nodes: List<NodeEntity>, context: Context): List<NodeEntity> {
        if (nodes.isEmpty()) return emptyList()

        // Simple scoring based on University OS rules
        // e.g., On Campus -> Prioritize Study/Research
        // e.g., High Recovery (Good Condition) -> Prioritize heavy tasks
        
        return nodes.sortedByDescending { node ->
            calculateScore(node, context)
        }
    }

    private fun calculateScore(node: NodeEntity, context: Context): Double {
        var score = 0.0

        // 1. Campus Multiplier
        if (context.isOnCampus && (node.type == ProjectType.STUDY || node.type == ProjectType.RESEARCH)) {
            score += 10.0
        }

        // 2. Deadline Pressure (if deadline exists)
        node.deadline?.let { deadline ->
            val hoursUntil = (deadline - System.currentTimeMillis()) / (1000 * 60 * 60)
            if (hoursUntil < 24) score += 20.0
            else if (hoursUntil < 72) score += 10.0
        }

        return score
    }
}
