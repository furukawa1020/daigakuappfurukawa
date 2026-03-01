package com.hatake.daigakuos.data.repository

import com.hatake.daigakuos.data.local.dao.WeeklyChallengeDao
import com.hatake.daigakuos.data.local.entity.WeeklyChallengeEntity
import com.hatake.daigakuos.domain.repository.WeeklyChallengeRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WeeklyChallengeRepositoryImpl @Inject constructor(
    private val dao: WeeklyChallengeDao
) : WeeklyChallengeRepository {
    override fun getChallengesForWeek(yearWeek: String): Flow<List<WeeklyChallengeEntity>> {
        return dao.getChallengesForWeek(yearWeek)
    }

    override suspend fun upsertChallenge(challenge: WeeklyChallengeEntity) {
        dao.upsertChallenge(challenge)
    }

    override suspend fun updateChallenge(challenge: WeeklyChallengeEntity) {
        dao.updateChallenge(challenge)
    }
}
