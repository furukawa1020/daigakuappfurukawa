package com.hatake.daigakuos.ui.finish

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.NodeType
import com.hatake.daigakuos.domain.usecase.FinalizeSessionUseCase
import com.hatake.daigakuos.domain.usecase.GetFinishSuggestionsUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class FinishUiState(
    val suggestions: List<NodeEntity> = emptyList(),
    val isLoading: Boolean = false
)

@HiltViewModel
class FinishViewModel @Inject constructor(
    private val finalizeSessionUseCase: FinalizeSessionUseCase,
    private val getFinishSuggestionsUseCase: GetFinishSuggestionsUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(FinishUiState())
    val uiState: StateFlow<FinishUiState> = _uiState.asStateFlow()

    init {
        loadSuggestions()
    }

    private fun loadSuggestions() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(suggestions = getFinishSuggestionsUseCase())
        }
    }

    fun finalizeSession(
        sessionId: String,
        selectedNodeId: String?,
        newNodeTitle: String?,
        newNodeType: NodeType?,
        minutes: Int,
        focus: Int,
        onSuccess: () -> Unit
    ) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            finalizeSessionUseCase(
                sessionId = sessionId,
                selectedNodeId = selectedNodeId,
                newNodeTitle = newNodeTitle,
                newNodeType = newNodeType,
                selfReportMin = minutes,
                focus = focus
            )
            _uiState.value = _uiState.value.copy(isLoading = false)
            onSuccess()
        }
    }
}
