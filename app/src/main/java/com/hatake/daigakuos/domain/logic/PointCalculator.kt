package com.hatake.daigakuos.domain.logic

import com.hatake.daigakuos.data.local.entity.NodeEventEntity
import com.hatake.daigakuos.data.local.entity.ProjectType
import javax.inject.Inject

/**
 * Core Logic for: 成果 = (試行回数 × 多様 + 察知) * (回復 + 生活力)
 */
class PointCalculator @Inject constructor() {

    data class Inputs(
        val completedNodeTypesToday: List<ProjectType>, // For Diversity
        val isOnCampus: Boolean, // For Awareness
        val focusLevel: Int, // 1-5, For Awareness
        val estimateMinutes: Int, // For granularity check (Awareness)
        val recentRecoveryCount: Int, // For Recovery
        val currentStreakDays: Int // For Livelihood
    )

    fun calculate(inputs: Inputs): CalculationResult {
        // --- 1. 左辺: (試行回数 × 多様 + 察知) ---

        // 試行回数 (Trial): 1 action = 1.0 base
        val trial = 1.0f

        // 多様 (Diversity): Calculate entropy or unique types multiplier based on History
        // If this is the Nth type today...
        val uniqueTypes = inputs.completedNodeTypesToday.toSet().size
        val diversityMultiplier = when (uniqueTypes) {
            0 -> 1.0f // First one
            1 -> 1.0f // Same type as before (or just one type so far)
            2 -> 1.2f
            3 -> 1.5f
            else -> 1.8f
        }
        
        // 察知 (Awareness): Sensitivity to context & self
        // Components: Location (+0.5), Focus (+0.1 per star above 3?), Granularity
        var awareness = 0.0f
        
        if (inputs.isOnCampus) {
            awareness += 0.5f // Campus is high awareness
        }
        
        // Focus: 3 is neutral. 4=+0.1, 5=+0.2. 1=-0.1? Or just additive bonus?
        // Let's make it positive only to encourage reporting.
        awareness += (inputs.focusLevel * 0.1f) 
        
        // Granularity bonus: Smaller tasks (<= 25m) imply better breakdown/awareness than 90m chunks
        if (inputs.estimateMinutes <= 25) {
            awareness += 0.2f
        }

        val leftTerm = (trial * diversityMultiplier) + awareness


        // --- 2. 右辺: (回復 + 生活力) ---

        // 回復 (Recovery): Did you rest recently?
        // If recentRecoveryCount > 0 -> 1.0 (Active), else 0.8 (Tired)? 
        // Or additive: Base 1.0 + 0.2 per recovery?
        // Let's assume Base 0.5 + Recovery. If no recovery, it drags down?
        // User formula implies these are multipliers.
        
        var recoveryScore = 0.5f // Base condition
        if (inputs.recentRecoveryCount > 0) {
            recoveryScore += 0.5f // Fully recovered state
        }
        // Maybe time of day influences this? (Ignored for now)

        // 生活力 (Livelihood): Consistency (Streak) + Admin/Maintenance capability
        // Here we use Streak.
        // 0 days = 0.5, 7 days = 1.0?
        val livelihoodScore = 0.5f + (inputs.currentStreakDays * 0.1f).coerceAtMost(0.5f)

        val rightTerm = recoveryScore + livelihoodScore
        
        // Final
        val totalPoints = leftTerm * rightTerm
        
        return CalculationResult(
            totalPoints = totalPoints,
            breakdown = "($trial * $diversityMultiplier + $awareness) * ($recoveryScore + $livelihoodScore)"
        )
    }
    
    data class CalculationResult(
        val totalPoints: Float,
        val breakdown: String
    )
}
