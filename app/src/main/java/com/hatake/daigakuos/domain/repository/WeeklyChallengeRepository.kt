package com.hatake.daigakuos.domain.repository

import com.hatake.daigakuos.data.local.entity.WeeklyChallengeEntity
import kotlinx.coroutines.flow.Flow

interface WeeklyChallengeRepository {
    fun getChallengesForWeek(yearWeek: String): Flow<List<WeeklyChallengeEntity>>
    suspend fun upsertChallenge(challenge: WeeklyChallengeEntity)
    suspend fun updateChallenge(challenge: WeeklyChallengeEntity)
}
