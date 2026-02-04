package com.hatake.daigakuos.domain.repository

import com.hatake.daigakuos.data.local.entity.NodeEntity
import kotlinx.coroutines.flow.Flow

interface NodeRepository {
    // Flow Data Source
    fun getActiveNodes(): Flow<List<NodeEntity>>
    fun getNodesByParent(projectId: Long, parentId: Long?): Flow<List<NodeEntity>>

    // Basic CRUD
    suspend fun insertNode(node: NodeEntity): Long
    suspend fun updateNode(node: NodeEntity)

    // Business Logic
    suspend fun completeNode(
        nodeId: Long, 
        actualMinutes: Int, 
        focusLevel: Int, 
        isOnCampus: Boolean, 
        streakDays: Int
    )
}
