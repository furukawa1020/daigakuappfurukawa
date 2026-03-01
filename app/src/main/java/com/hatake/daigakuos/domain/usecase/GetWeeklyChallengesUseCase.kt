package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.entity.WeeklyChallengeEntity
import com.hatake.daigakuos.domain.repository.WeeklyChallengeRepository
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate
import java.time.temporal.IsoFields
import javax.inject.Inject

class GetWeeklyChallengesUseCase @Inject constructor(
    private val repository: WeeklyChallengeRepository
) {
    operator fun invoke(): Flow<List<WeeklyChallengeEntity>> {
        val today = LocalDate.now()
        val year = today.get(IsoFields.WEEK_BASED_YEAR)
        val week = today.get(IsoFields.WEEK_OF_WEEK_BASED_YEAR)
        val yearWeek = "$year-W${week.toString().padStart(2, '0')}"
        
        return repository.getChallengesForWeek(yearWeek)
    }
}
