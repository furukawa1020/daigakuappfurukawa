package com.hatake.daigakuos.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.domain.repository.UserContextRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeUiState(
    val currentPoints: Float = 1250f,
    val isOnCampus: Boolean = true,
    val recommendations: List<NodeEntity> = emptyList()
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val getRecommendedNodesUseCase: com.hatake.daigakuos.domain.usecase.GetRecommendedNodesUseCase,
    private val userContextRepository: UserContextRepository,
    private val sessionDao: com.hatake.daigakuos.data.local.dao.SessionDao
) : ViewModel() {

    private val _recommendedNodes = MutableStateFlow<List<NodeEntity>>(emptyList())

    // Combined UI State
    val uiState: StateFlow<HomeUiState> = combine(
        _recommendedNodes,
        userContextRepository.isOnCampus,
        userContextRepository.currentMode,
        sessionDao.getTotalPointsFlow().map { it?.toFloat() ?: 0f }
    ) { nodes, onCampus, mode, points ->
        HomeUiState(
            currentPoints = points,
            isOnCampus = onCampus,
            recommendations = nodes
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = HomeUiState()
    )

    init {
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
