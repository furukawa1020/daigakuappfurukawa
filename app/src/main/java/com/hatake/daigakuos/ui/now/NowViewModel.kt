package com.hatake.daigakuos.ui.now

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.dao.NodeDao
import com.hatake.daigakuos.domain.repository.UserContextRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class NowUiState(
    val nodeTitle: String = "集中セッション",
    val isLoading: Boolean = false
)

@HiltViewModel
class NowViewModel @Inject constructor(
    private val startSessionUseCase: com.hatake.daigakuos.domain.usecase.StartSessionUseCase,
    private val finishSessionUseCase: com.hatake.daigakuos.domain.usecase.FinishSessionUseCase,
    private val userContextRepository: UserContextRepository,
    private val nodeDao: NodeDao // Direct DAO usage for simple fetch
) : ViewModel() {

    var currentSessionId: String? = null // Public for UI
    
    private val _uiState = MutableStateFlow(NowUiState())
    val uiState: StateFlow<NowUiState> = _uiState.asStateFlow()

    fun startSession(nodeId: String?) {
        viewModelScope.launch {
            // 1. Fetch Node Title
            if (nodeId != null) {
                val node = nodeDao.getNodeById(nodeId)
                if (node != null) {
                    _uiState.value = _uiState.value.copy(nodeTitle = node.title)
                }
            }

            // 2. Start Session
            if (currentSessionId == null) {
                val isOnCampus = userContextRepository.isOnCampus.value
                val mode = userContextRepository.currentMode.value
                
                currentSessionId = startSessionUseCase(
                    nodeId = nodeId,
                    mode = mode.name,
                    onCampus = isOnCampus
                )
            }
        }
    }

    fun completeSession(selfReportMinutes: Int, focusLevel: Int, onComplete: () -> Unit) {
        viewModelScope.launch {
            val sessionId = currentSessionId
            if (sessionId != null) {
                finishSessionUseCase(
                    sessionId = sessionId,
                    selfReportMin = selfReportMinutes,
                    focus = focusLevel
                )
            }
            onComplete()
            currentSessionId = null
        }
    }
}
