package com.hatake.daigakuos.ui.stats

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.dao.AggDao
import com.hatake.daigakuos.data.local.dao.SessionDao
import com.hatake.daigakuos.data.local.entity.DailyAggEntity
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class StatsUiState(
    val totalPoints: Double = 0.0,
    val dailyAggs: List<DailyAggEntity> = emptyList(),
    val recentSessions: List<com.hatake.daigakuos.data.local.entity.SessionEntity> = emptyList(),
    val creatureStage: CreatureStage = CreatureStage.EGG,
    val weeklyChallenges: List<com.hatake.daigakuos.data.local.entity.WeeklyChallengeEntity> = emptyList()
)

enum class CreatureStage {
    EGG, BABY, CHILD, ADULT, MASTER
}

@HiltViewModel
class StatsViewModel @Inject constructor(
    private val aggDao: AggDao,
    private val sessionDao: SessionDao,
    private val updateSessionUseCase: com.hatake.daigakuos.domain.usecase.UpdateSessionUseCase,
    private val deleteSessionUseCase: com.hatake.daigakuos.domain.usecase.DeleteSessionUseCase,
    private val syncWeeklyChallengesUseCase: com.hatake.daigakuos.domain.usecase.SyncWeeklyChallengesUseCase,
    private val getWeeklyChallengesUseCase: com.hatake.daigakuos.domain.usecase.GetWeeklyChallengesUseCase,
    private val claimWeeklyChallengeRewardUseCase: com.hatake.daigakuos.domain.usecase.ClaimWeeklyChallengeRewardUseCase
) : ViewModel() {

    init {
        viewModelScope.launch {
            syncWeeklyChallengesUseCase()
        }
    }

    val uiState: StateFlow<StatsUiState> = combine(
        sessionDao.getTotalPointsFlow(),
        aggDao.getAggRange(365),
        sessionDao.getRecentSessions(),
        getWeeklyChallengesUseCase()
    ) { points, aggs, history, challenges ->
        StatsUiState(
            totalPoints = points,
            dailyAggs = aggs,
            recentSessions = history,
            creatureStage = determineStage(points),
            weeklyChallenges = challenges
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = StatsUiState()
    )

    fun updateSessionTitle(sessionId: String, newTitle: String) {
        viewModelScope.launch {
            updateSessionUseCase(sessionId, newTitle)
        }
    }

    fun deleteSession(sessionId: String) {
        viewModelScope.launch {
            deleteSessionUseCase(sessionId)
        }
    }

    fun claimReward(challenge: com.hatake.daigakuos.data.local.entity.WeeklyChallengeEntity) {
        viewModelScope.launch {
            claimWeeklyChallengeRewardUseCase(challenge)
        }
    }

    private fun determineStage(points: Double): CreatureStage {
        return when {
            points < 100 -> CreatureStage.EGG
            points < 500 -> CreatureStage.BABY
            points < 2000 -> CreatureStage.CHILD
            points < 10000 -> CreatureStage.ADULT
            else -> CreatureStage.MASTER
        }
    }
}
