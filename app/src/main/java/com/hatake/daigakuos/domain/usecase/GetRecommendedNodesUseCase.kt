package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.NodeDao
import com.hatake.daigakuos.data.local.entity.NodeEntity
import javax.inject.Inject

class GetRecommendedNodesUseCase @Inject constructor(
    private val nodeDao: NodeDao
) {
    suspend operator fun invoke(onCampus: Boolean): List<NodeEntity> {
        // MVP Logic: Get all TODO nodes, sort by priority/deadline.
        // User spec mentions "Score", but for Phase 1 refactor, we just return top 3.
        val candidates = nodeDao.getAllTodoNodes()
        
        // Simple Sort: Priority DESC, then Creation DESC
        return candidates.sortedByDescending { it.priority }.take(3)
    }
}
