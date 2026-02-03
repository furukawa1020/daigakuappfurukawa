package com.hatake.daigakuos.ui.tree

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.ProjectEntity
import com.hatake.daigakuos.data.local.entity.NodeType
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TreeViewModel @Inject constructor(
    private val getTreeUseCase: com.hatake.daigakuos.domain.usecase.GetTreeUseCase,
    private val upsertNodeUseCase: com.hatake.daigakuos.domain.usecase.UpsertNodeUseCase,
    private val projectDao: com.hatake.daigakuos.data.local.dao.ProjectDao
) : ViewModel() {

    private val _currentProject = MutableStateFlow<ProjectEntity?>(null)

    @OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
    val nodes: StateFlow<List<NodeEntity>> = _currentProject
        .flatMapLatest { project ->
            if (project != null) {
                getTreeUseCase(project.id)
            } else {
                flowOf(emptyList())
            }
        }
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
            projectDao.getAllProjects().collect { projects ->
                if (projects.isNotEmpty()) {
                    _currentProject.value = projects.first()
                } else {
                    val defaultProject = ProjectEntity(title = "メインプロジェクト")
                    projectDao.insertProject(defaultProject)
                }
            }
        }
    }

    fun addNode(title: String, minutes: Int, type: NodeType) {
        val project = _currentProject.value ?: return
        
        viewModelScope.launch {
            upsertNodeUseCase(
                projectId = project.id,
                title = title,
                type = type,
                minutes = minutes
            )
        }
    }
}
