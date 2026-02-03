package com.hatake.daigakuos.ui.now

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.domain.repository.NodeRepository
import com.hatake.daigakuos.domain.repository.UserContextRepository
import com.hatake.daigakuos.domain.usecase.CompleteNodeUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class NowViewModel @Inject constructor(
    private val completeNodeUseCase: CompleteNodeUseCase,
    private val nodeRepository: NodeRepository,
    private val userContextRepository: UserContextRepository
) : ViewModel() {

    // Ideally we fetch the Node details
    private val _currentNode = MutableStateFlow<NodeEntity?>(null)
    val currentNode = _currentNode.asStateFlow()

    fun loadNode(nodeId: Long) {
        viewModelScope.launch {
            // Mock fetching node
            // _currentNode.value = nodeRepository.getNode(nodeId)
        }
    }

    fun completeTask(actualMinutes: Int, focusLevel: Int) {
        val node = _currentNode.value ?: return
        val isOnCampus = userContextRepository.isOnCampus.value

        viewModelScope.launch {
            completeNodeUseCase(
                node = node,
                actualMinutes = actualMinutes,
                focusLevel = focusLevel,
                isOnCampus = isOnCampus
            )
            // Trigger navigation back or show success in UI
        }
    }
}
