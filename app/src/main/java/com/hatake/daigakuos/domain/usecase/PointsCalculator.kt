package com.hatake.daigakuos.domain.usecase

import javax.inject.Inject

class PointsCalculator @Inject constructor() {

    inline fun computePoints(
        base: Double = 1.0,
        selfReportMin: Int?,
        focus: Int?,
        onCampus: Boolean,
        campusBaseMultiplier: Double,
        streakMultiplier: Double,
        recoveryMultiplier: Double = 1.0
    ): Double {
        // Time Multiplier (T)
        val t = getTimeMultiplier(selfReportMin ?: 25)

        // Focus Multiplier (F)
        val f = getFocusMultiplier(focus ?: 3)

        // Campus Location Multiplier (L)
        val l = if (onCampus) campusBaseMultiplier else 1.0

        // Final Calculation
        return base * t * f * l * streakMultiplier * recoveryMultiplier
    }
    
    private inline fun getTimeMultiplier(minutes: Int): Double = when (minutes) {
        in 0..15 -> 0.6
        in 16..35 -> 1.0
        in 36..70 -> 1.6
        in 71..105 -> 2.4
        else -> 3.0
    }
    
    private inline fun getFocusMultiplier(focus: Int): Double = when (focus) {
        1 -> 0.8
        2 -> 0.9
        3 -> 1.0
        4 -> 1.1
        5 -> 1.2
        else -> 1.0
    }
}
