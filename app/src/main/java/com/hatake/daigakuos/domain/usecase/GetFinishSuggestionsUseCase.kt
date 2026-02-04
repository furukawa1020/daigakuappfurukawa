package com.hatake.daigakuos.domain.usecase

import com.hatake.daigakuos.data.local.dao.NodeDao
import com.hatake.daigakuos.data.local.entity.NodeEntity
import javax.inject.Inject

class GetFinishSuggestionsUseCase @Inject constructor(
    private val nodeDao: NodeDao
) {
    suspend operator fun invoke(): List<NodeEntity> {
        // Logic: 
        // 1. Recent History (Not implemented efficiently yet, so skip or use recently updated nodes)
        // 2. Pending Tasks (High Priority)
        // 3. Draft/Inbox?
        
        // For Phase 1 MVP, just return ALL pending nodes sorted by Priority/Update.
        // Or "Recently Updated" nodes (which includes what we just worked on if we linked it).
        
        // Let's use getPendingNodes for now.
        // Ideally we want "Recent" across all types.
        val pending = nodeDao.getAllTodoNodes() 
        return pending.take(5) // Top 5
    }
}
