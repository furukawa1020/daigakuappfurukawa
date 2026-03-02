package com.hatake.daigakuos.domain.logic

import javax.inject.Inject

/**
 * Core Logic for: 成果 = (試行回数 × 多様 + 察知) * (回復 + 生活力)
 */
class PointCalculator @Inject constructor() {

    data class Inputs(
        val selfReportMin: Int, // For Trial
        val focusLevel: Int, // 1-5, For Awareness
        val isOnCampus: Boolean, // For Awareness
        val uniqueTypesCompletedToday: Int, // For Diversity (1 to 4)
        val recentRecoveryCount: Int, // For Recovery
        val currentStreakDays: Int // For Livelihood
    )

    fun calculate(inputs: Inputs): CalculationResult {
        // --- 1. 左辺: (試行回数 × 多様 + 察知) ---

        // 試行回数 (Trial): 1 action base is Time (Minutes)
        val trial = inputs.selfReportMin.toDouble()

        // 多様 (Diversity): Multiplier based on different active node types today
        val diversityMultiplier = when (inputs.uniqueTypesCompletedToday) {
            0, 1 -> 1.0  // First or only one type
            2 -> 1.2
            3 -> 1.5
            else -> 1.8
        }
        
        // 察知 (Awareness): Sensitivity to context & self
        // Increased weight to ensure it makes a noticeable difference.
        var awareness = 0.0
        
        if (inputs.isOnCampus) {
            awareness += 5.0 // Campus is high awareness
        }
        
        // Focus: 3 is neutral. 4=+2.0, 5=+4.0, 1=-2.0
        awareness += ((inputs.focusLevel - 3) * 2.0) 
        
        // Granularity bonus: Smaller tasks (<= 25m) imply better breakdown/awareness
        if (inputs.selfReportMin in 1..25) {
            awareness += 3.0
        }

        val leftTerm = (trial * diversityMultiplier) + awareness


        // --- 2. 右辺: (回復 + 生活力) ---

        // 回復 (Recovery): Base 1.0. If rested recently, boost.
        val recoveryScore = if (inputs.recentRecoveryCount > 0) 1.2 else 1.0

        // 生活力 (Livelihood): Consistency (Streak)
        // 1.0 Base + 0.1 per day (Max 1.5 at 5 days)
        val livelihoodScore = 1.0 + (inputs.currentStreakDays * 0.1).coerceAtMost(0.5)

        val rightTerm = recoveryScore + livelihoodScore
        
        // Final Output
        val totalPoints = (leftTerm * rightTerm).coerceAtLeast(0.0) // Prevent negative points safely
        
        return CalculationResult(
            totalPoints = totalPoints,
            breakdown = "($trial * $diversityMultiplier + $awareness) * ($recoveryScore + $livelihoodScore)"
        )
    }
    
    data class CalculationResult(
        val totalPoints: Double,
        val breakdown: String
    )
}
