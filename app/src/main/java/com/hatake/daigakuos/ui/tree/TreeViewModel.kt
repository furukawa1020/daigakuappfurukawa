package com.hatake.daigakuos.ui.tree

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
// import androidx.lifecycle.viewmodel.compose.viewModel // Not needed if Hilt
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.ProjectEntity
import com.hatake.daigakuos.data.local.entity.ProjectType
import com.hatake.daigakuos.domain.repository.NodeRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TreeViewModel @Inject constructor(
    private val nodeRepository: NodeRepository
) : ViewModel() {

    // Expose nodes directly from Flow
    // We can filter/sort here if needed
    val nodes: StateFlow<List<NodeEntity>> = nodeRepository.getActiveNodes()
        .stateIn(
            scope = viewModelScope,
            started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    init {
        checkAndSeed()
    }

    private fun checkAndSeed() {
        viewModelScope.launch {
            // Simple check: If flow emits empty list initially, maybe seed?
            // Note: This is a bit racy with Flow, but fine for MVP.
            // Better to use a dedicated "getCount" in Repo, but sticking to valid methods:
            // Let's just provide a manual "Seed" if empty?
            // actually, let's just wait for user input.
        }
    }

    fun addNode(title: String, minutes: Int, type: ProjectType) {
        viewModelScope.launch {
            nodeRepository.insertNode(NodeEntity(
                projectId = 1, // Default project for specific MVP
                title = title,
                type = type,
                estimateMinutes = minutes
            ))
        }
    }
}
