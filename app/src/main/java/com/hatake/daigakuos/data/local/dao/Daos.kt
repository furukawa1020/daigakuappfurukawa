package com.hatake.daigakuos.data.local.dao

import androidx.room.*
import com.hatake.daigakuos.data.local.entity.*
import kotlinx.coroutines.flow.Flow

@Dao
interface ProjectDao {
    @Query("SELECT * FROM projects")
    fun getAllProjects(): Flow<List<ProjectEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProject(project: ProjectEntity): Long

    @Delete
    suspend fun deleteProject(project: ProjectEntity)
}

@Dao
interface NodeDao {
    @Query("SELECT * FROM nodes WHERE status = 'TODO' ORDER BY priority_score DESC, createdAt DESC")
    fun getActiveNodes(): Flow<List<NodeEntity>>

    @Query("SELECT * FROM nodes WHERE projectId = :projectId AND parentId = :parentId")
    fun getNodesByParent(projectId: Long, parentId: Long?): Flow<List<NodeEntity>>
    
    // Get recommendations: Todo items, prioritized
    // In a real app, this query would be more complex or handled in Domain layer
    @Query("SELECT * FROM nodes WHERE status = 'TODO'") 
    suspend fun getAllTodoNodes(): List<NodeEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNode(node: NodeEntity): Long

    @Update
    suspend fun updateNode(node: NodeEntity)
    
    @Query("UPDATE nodes SET status = 'DONE', completedAt = :timestamp WHERE id = :id")
    suspend fun markAsDone(id: Long, timestamp: Long)
}

@Dao
interface EventDao {
    @Insert
    suspend fun insertNodeEvent(event: NodeEventEntity)

    @Insert
    suspend fun insertRecoveryEvent(event: RecoveryEventEntity)

    // Check for recovery events in last X hours
    @Query("SELECT COUNT(*) FROM recovery_events WHERE timestamp > :sinceTimestamp")
    suspend fun getRecentRecoveryCount(sinceTimestamp: Long): Int

    // Get today's node events for Diversity calculation
    @Query("SELECT * FROM node_events WHERE timestamp >= :startOfDay")
    suspend fun getTodayEvents(startOfDay: Long): List<NodeEventEntity>
    
    @Query("SELECT * FROM node_events ORDER BY timestamp DESC LIMIT 100")
    fun getRecentEvents(): Flow<List<NodeEventEntity>>
}

@Dao
interface DailyMetricDao {
    @Query("SELECT * FROM daily_metrics WHERE dateKey = :date")
    suspend fun getMetric(date: String): DailyMetricEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(metric: DailyMetricEntity)
    
    @Query("SELECT * FROM daily_metrics ORDER BY dateKey DESC LIMIT 365")
    fun getGrassData(): Flow<List<DailyMetricEntity>>
}
