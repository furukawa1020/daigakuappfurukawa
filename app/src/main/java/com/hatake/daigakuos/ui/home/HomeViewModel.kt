package com.hatake.daigakuos.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.entity.Mode
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.domain.repository.UserContextRepository
import com.hatake.daigakuos.domain.usecase.GetRecommendationUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeUiState(
    val currentPoints: Float = 0f,
    val isOnCampus: Boolean = false,
    val recommendations: List<NodeEntity> = emptyList(),
    val currentMode: Mode = Mode.DEFAULT
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val getRecommendationUseCase: GetRecommendationUseCase,
    private val userContextRepository: UserContextRepository
    // private val statsRepository: StatsRepository // For points
) : ViewModel() {

    private val _currentMode = MutableStateFlow(Mode.DEFAULT)
    
    // In a real app, we would observe points from StatsRepository flow
    private val _points = MutableStateFlow(1250f) 

    val uiState: StateFlow<HomeUiState> = combine(
        userContextRepository.isOnCampus,
        _currentMode,
        _points
    ) { onCampus, mode, points ->
        val recs = getRecommendationUseCase(mode)
        HomeUiState(
            currentPoints = points,
            isOnCampus = onCampus,
            recommendations = recs,
            currentMode = mode
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = HomeUiState()
    )

    fun setMode(mode: Mode) {
        _currentMode.value = mode
    }
}
