package com.hatake.daigakuos.data.repository

import com.hatake.daigakuos.data.local.dao.NodeDao
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.NodeStatus
import com.hatake.daigakuos.domain.repository.NodeRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NodeRepositoryImpl @Inject constructor(
    private val nodeDao: NodeDao
) : NodeRepository {

    override fun getActiveNodes(): Flow<List<NodeEntity>> {
        return nodeDao.getActiveNodes()
    }

    override fun getNodesByParent(projectId: Long, parentId: Long?): Flow<List<NodeEntity>> {
        return nodeDao.getNodesByParent(projectId, parentId)
    }

    override suspend fun insertNode(node: NodeEntity): Long {
        return nodeDao.insertNode(node)
    }

    override suspend fun updateNode(node: NodeEntity) {
        nodeDao.updateNode(node)
    }

    override suspend fun completeNode(
        nodeId: Long,
        actualMinutes: Int,
        focusLevel: Int,
        isOnCampus: Boolean,
        streakDays: Int
    ) {
        // Business Logic for completion
        // 1. Calculate points (Simplified for now, real logic in UseCase or here)
        val timestamp = System.currentTimeMillis()
        
        // 2. Mark as done in DB
        nodeDao.markAsDone(nodeId, timestamp)
        
        // 3. (Optional) Create Event log here or via EventRepository
    }
}
