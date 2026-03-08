package com.hatake.daigakuos.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.WalletEntity
import com.hatake.daigakuos.domain.repository.UserContextRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeUiState(
    val currentPoints: Float = 1250f,
    val isOnCampus: Boolean = true,
    val recommendations: List<NodeEntity> = emptyList(),
    val organismState: com.hatake.daigakuos.domain.logic.OrganismGrowthLogic.OrganismState? = null,
    val mokoCoins: Int = 0,
    val starCrystals: Int = 0,
    val campusGems: Int = 0,
    val streak: Int = 0
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val getRecommendedNodesUseCase: com.hatake.daigakuos.domain.usecase.GetRecommendedNodesUseCase,
    private val userContextRepository: UserContextRepository,
    private val sessionDao: com.hatake.daigakuos.data.local.dao.SessionDao,
    private val walletDao: com.hatake.daigakuos.data.local.dao.WalletDao,
    private val getStreakUseCase: com.hatake.daigakuos.domain.usecase.GetStreakUseCase,
    private val organismGrowthLogic: com.hatake.daigakuos.domain.logic.OrganismGrowthLogic,
    private val soundManager: com.hatake.daigakuos.utils.SoundManager
) : ViewModel() {

    private val _recommendedNodes = MutableStateFlow<List<NodeEntity>>(emptyList())
    private val _streak = MutableStateFlow(0)
    private var previousLevel = -1

    // Combined UI State (5 flows + streak using combine overload trick)
    val uiState: StateFlow<HomeUiState> = combine(
        _recommendedNodes,
        userContextRepository.isOnCampus,
        sessionDao.getTotalPointsFlow().map { it.toFloat() },
        walletDao.getWallet().map { it ?: WalletEntity() },
        _streak
    ) { nodes, onCampus, points, wallet, streak ->
        val state = organismGrowthLogic.calculateGrowth(points, points, points)
        if (previousLevel != -1 && state.level > previousLevel) {
            soundManager.playLevelUp()
        }
        previousLevel = state.level
        HomeUiState(
            currentPoints = points,
            isOnCampus = onCampus,
            recommendations = nodes,
            organismState = state,
            mokoCoins = wallet.mokoCoins,
            starCrystals = wallet.starCrystals,
            campusGems = wallet.campusGems,
            streak = streak
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = HomeUiState()
    )

    init {
        viewModelScope.launch { walletDao.initWallet() }
        refreshRecommendations()
        refreshStreak()
    }

    fun refreshRecommendations() {
        viewModelScope.launch {
            val isOnCampus = userContextRepository.isOnCampus.value
            _recommendedNodes.value = getRecommendedNodesUseCase(isOnCampus)
        }
    }

    fun refreshStreak() {
        viewModelScope.launch {
            _streak.value = getStreakUseCase()
        }
    }

    fun setMode(mode: com.hatake.daigakuos.data.local.entity.Mode) {
        viewModelScope.launch {
            userContextRepository.setMode(mode)
        }
    }
}
