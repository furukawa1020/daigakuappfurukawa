package com.hatake.daigakuos.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.domain.repository.UserContextRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

import com.hatake.daigakuos.data.local.entity.WalletEntity

data class HomeUiState(
    val currentPoints: Float = 1250f,
    val isOnCampus: Boolean = true,
    val recommendations: List<NodeEntity> = emptyList(),
    val organismState: com.hatake.daigakuos.domain.logic.OrganismGrowthLogic.OrganismState? = null,
    val mokoCoins: Int = 0,
    val starCrystals: Int = 0,
    val campusGems: Int = 0
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val getRecommendedNodesUseCase: com.hatake.daigakuos.domain.usecase.GetRecommendedNodesUseCase,
    private val userContextRepository: UserContextRepository,
    private val sessionDao: com.hatake.daigakuos.data.local.dao.SessionDao,
    private val walletDao: com.hatake.daigakuos.data.local.dao.WalletDao,
    private val organismGrowthLogic: com.hatake.daigakuos.domain.logic.OrganismGrowthLogic,
    private val soundManager: com.hatake.daigakuos.utils.SoundManager
) : ViewModel() {

    private val _recommendedNodes = MutableStateFlow<List<NodeEntity>>(emptyList())
    
    private var previousLevel = -1

    // Combined UI State
    val uiState: StateFlow<HomeUiState> = combine(
        _recommendedNodes,
        userContextRepository.isOnCampus,
        userContextRepository.currentMode,
        sessionDao.getTotalPointsFlow().map { it.toFloat() },
        walletDao.getWallet().map { it ?: WalletEntity() }
    ) { nodes, onCampus, mode, points, wallet ->
        // For Organism Level calculation
        val state = organismGrowthLogic.calculateGrowth(points, points, points) // Using total points as a proxy for all
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
            campusGems = wallet.campusGems
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = HomeUiState()
    )

    init {
        viewModelScope.launch { walletDao.initWallet() }
        refreshRecommendations()
    }

    fun refreshRecommendations() {
        viewModelScope.launch {
            val isOnCampus = userContextRepository.isOnCampus.value
            _recommendedNodes.value = getRecommendedNodesUseCase(isOnCampus)
        }
    }
    
    fun setMode(mode: com.hatake.daigakuos.data.local.entity.Mode) {
        viewModelScope.launch {
            userContextRepository.setMode(mode)
        }
    }
}
