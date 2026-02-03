package com.hatake.daigakuos.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.domain.usecase.GetRecommendationUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import com.hatake.daigakuos.domain.repository.UserContextRepository
import com.hatake.daigakuos.data.local.entity.Mode
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

data class HomeUiState(
    val currentPoints: Float = 1250f,
    val isOnCampus: Boolean = true,
    val recommendations: List<NodeEntity> = emptyList()
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val getRecommendationUseCase: GetRecommendationUseCase,
    private val userContextRepository: UserContextRepository
) : ViewModel() {

    private val _recommendedNodes = MutableStateFlow<List<NodeEntity>>(emptyList())
    // val recommendedNodes: StateFlow<List<NodeEntity>> = _recommendedNodes.asStateFlow()

    // Combined UI State
    val uiState: StateFlow<HomeUiState> = combine(
        _recommendedNodes,
        userContextRepository.isOnCampus, // Property access
        userContextRepository.currentMode   // Property access
    ) { nodes, onCampus, mode ->
        HomeUiState(
            currentPoints = 1250f, // Still dummy for now, connect to Points later
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
            // New UseCase fetches context internally and returns single best node (or null)
            val result = getRecommendationUseCase()
            
            _recommendedNodes.value = if (result != null) {
                listOf(result)
            } else {
                emptyList()
            }
        }
    }
    
    fun setMode(mode: Mode) {
        viewModelScope.launch {
            userContextRepository.setMode(mode)
        }
    }
}
