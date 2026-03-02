package com.hatake.daigakuos.domain.repository

import com.hatake.daigakuos.data.local.entity.NodeType

interface StatsRepository {
    suspend fun getTodayCompletedTypes(): List<NodeType>
    suspend fun getRecentRecoveryCount(): Int
    suspend fun getStreak(): Int
    fun getTotalPoints(): kotlinx.coroutines.flow.Flow<Float>
    suspend fun logSession(nodeId: Long, durationMillis: Long, points: Float)
    suspend fun addPointsFromCompletedNode(nodeType: NodeType, points: Double, minutes: Int)
}
