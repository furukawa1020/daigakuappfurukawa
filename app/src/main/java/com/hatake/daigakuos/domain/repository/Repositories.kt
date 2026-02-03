package com.hatake.daigakuos.domain.repository

import com.hatake.daigakuos.data.local.entity.*
import kotlinx.coroutines.flow.Flow

interface NodeRepository {
    fun getActiveNodes(): Flow<List<NodeEntity>>
    suspend fun getTodoNodes(): List<NodeEntity>
    suspend fun createNode(node: NodeEntity): Long
    suspend fun completeNode(
        nodeId: Long, 
        actualMinutes: Int, 
        focusLevel: Int, 
        isOnCampus: Boolean,
        streakDays: Int
    )
}

interface StatsRepository {
    fun getDailyMetrics(): Flow<List<DailyMetricEntity>>
    suspend fun getStreak(): Int
    suspend fun getRecentRecoveryCount(): Int
    suspend fun getTodayCompletedTypes(): List<ProjectType>
}
