package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.WalletDao
import com.hatake.daigakuos.data.local.entity.WeeklyChallengeEntity
import com.hatake.daigakuos.domain.repository.WeeklyChallengeRepository
import javax.inject.Inject

class ClaimWeeklyChallengeRewardUseCase @Inject constructor(
    private val repository: WeeklyChallengeRepository,
    private val walletDao: WalletDao
) {
    suspend operator fun invoke(challenge: WeeklyChallengeEntity) {
        if (challenge.isCompleted && !challenge.isRewardClaimed) {
            if (challenge.rewardCoins > 0) walletDao.addMokoCoins(challenge.rewardCoins)
            if (challenge.rewardCrystals > 0) walletDao.addStarCrystals(challenge.rewardCrystals)
            repository.updateChallenge(challenge.copy(isRewardClaimed = true))
        }
    }
}
