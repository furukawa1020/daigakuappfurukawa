package com.hatake.daigakuos.domain.logic

import com.hatake.daigakuos.data.local.entity.ProjectType
import javax.inject.Inject

/**
 * Logic for the "Achievement Organism" (学習生物).
 * It grows based on point allocation.
 */
class OrganismGrowthLogic @Inject constructor() {

    enum class LimbSize {
        SMALL, MEDIUM, LARGE
    }
    
    data class OrganismState(
        val headSize: LimbSize, // Research
        val bodySize: LimbSize, // Study
        val handSize: LimbSize, // Make
        val level: Int
    )

    fun calculateGrowth(
        studyPoints: Float,
        researchPoints: Float,
        makePoints: Float
    ): OrganismState {
        // Simple logic: Thresholds determine size
        
        val head = when {
            researchPoints > 1000 -> LimbSize.LARGE
            researchPoints > 300 -> LimbSize.MEDIUM
            else -> LimbSize.SMALL
        }
        
        val body = when {
            studyPoints > 1000 -> LimbSize.LARGE
            studyPoints > 300 -> LimbSize.MEDIUM
            else -> LimbSize.SMALL
        }
        
        val hand = when {
            makePoints > 1000 -> LimbSize.LARGE
            makePoints > 300 -> LimbSize.MEDIUM
            else -> LimbSize.SMALL
        }
        
        val level = ((studyPoints + researchPoints + makePoints) / 500).toInt() + 1
        
        return OrganismState(head, body, hand, level)
    }
}
