package com.hatake.daigakuos.data.repository

import com.hatake.daigakuos.data.local.dao.EventDao
import com.hatake.daigakuos.data.local.dao.NodeDao
import com.hatake.daigakuos.data.local.entity.*
import com.hatake.daigakuos.domain.repository.NodeRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class NodeRepositoryImpl @Inject constructor(
    private val nodeDao: NodeDao,
    private val eventDao: EventDao
) : NodeRepository {

    override fun getActiveNodes(): Flow<List<NodeEntity>> {
        return nodeDao.getActiveNodes()
    }

    override suspend fun getTodoNodes(): List<NodeEntity> {
        return nodeDao.getAllTodoNodes()
    }

    override suspend fun createNode(node: NodeEntity): Long {
        return nodeDao.insertNode(node)
    }

    override suspend fun completeNode(
        nodeId: Long,
        actualMinutes: Int,
        focusLevel: Int,
        isOnCampus: Boolean,
        streakDays: Int
    ) {
        val now = System.currentTimeMillis()
        
        // 1. Mark Node Done
        nodeDao.markAsDone(nodeId, now)
        
        // 2. Log Event (simplified, real points should come from Calculator, passed in)
        // For MVP, we'll just log it. Point calculation logic is in UseCase but we didn't update Entity to store it from there.
        // Let's assume we log it for now.
        
        val event = NodeEventEntity(
            nodeId = nodeId,
            timestamp = now,
            actualMinutes = actualMinutes,
            focusLevel = focusLevel,
            isOnCampus = isOnCampus,
            diversityScore = 1.0f, // Placeholder
            recoveryMultiplier = 1.0f, // Placeholder
            finalPoints = 100f // Placeholder
        )
        eventDao.insertNodeEvent(event)
    }
}
