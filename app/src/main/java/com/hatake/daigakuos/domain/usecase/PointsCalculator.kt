package com.hatake.daigakuos.domain.usecase

import javax.inject.Inject

class PointsCalculator @Inject constructor() {

    fun computePoints(
        base: Double = 1.0,
        selfReportMin: Int?,
        focus: Int?,
        onCampus: Boolean,
        campusBaseMultiplier: Double, // from Settings
        streakMultiplier: Double,     // from Streak calculation
        recoveryMultiplier: Double = 1.0
    ): Double {
        // Time Multiplier (T)
        // 10->0.6, 25->1.0, 50->1.6, 90->2.4, 120->3.0
        // Simple mapping or interpolation? Spec implies specific steps.
        val t = when (selfReportMin ?: 25) {
            in 0..15 -> 0.6
            in 16..35 -> 1.0
            in 36..70 -> 1.6
            in 71..105 -> 2.4
            else -> 3.0
        }

        // Focus Multiplier (F)
        // 1->0.8, 2->0.9, 3->1.0, 4->1.1, 5->1.2
        val f = when (focus ?: 3) {
            1 -> 0.8
            2 -> 0.9
            3 -> 1.0
            4 -> 1.1
            5 -> 1.2
            else -> 1.0
        }

        // Campus Location Multiplier (L)
        val l = if (onCampus) campusBaseMultiplier else 1.0

        // Final Calculation
        // base * T * F * L * streakMul * recoveryMul
        return base * t * f * l * streakMultiplier * recoveryMultiplier
    }
}
