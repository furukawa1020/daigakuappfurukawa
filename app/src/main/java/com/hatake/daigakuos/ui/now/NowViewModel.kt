package com.hatake.daigakuos.ui.now

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.domain.repository.UserContextRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class NowViewModel @Inject constructor(
    private val startSessionUseCase: com.hatake.daigakuos.domain.usecase.StartSessionUseCase,
    private val finishSessionUseCase: com.hatake.daigakuos.domain.usecase.FinishSessionUseCase,
    private val userContextRepository: UserContextRepository
) : ViewModel() {

    private var currentSessionId: String? = null

    fun startSession(nodeId: String?) {
        viewModelScope.launch {
            if (currentSessionId == null) {
                // Get Context
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
