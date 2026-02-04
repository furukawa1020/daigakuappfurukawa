package com.hatake.daigakuos.data.local.dao

import androidx.room.*
import com.hatake.daigakuos.data.local.entity.*
import kotlinx.coroutines.flow.Flow

@Dao
interface ProjectDao {
    @Query("SELECT * FROM projects ORDER BY orderIndex ASC")
    fun getAllProjects(): Flow<List<ProjectEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProject(project: ProjectEntity)

    @Delete
    suspend fun deleteProject(project: ProjectEntity)

    @Query("SELECT * FROM projects LIMIT 1")
    suspend fun findDefaultProject(): ProjectEntity?
}

@Dao
interface NodeDao {
    @Query("SELECT * FROM nodes WHERE projectId = :projectId ORDER BY createdAt DESC")
    fun getTree(projectId: String): Flow<List<NodeEntity>>

    @Query("SELECT * FROM nodes WHERE type = :type AND status = 'TODO' ORDER BY priority DESC")
    fun getPendingNodes(type: String): Flow<List<NodeEntity>>
    
    @Query("SELECT * FROM nodes WHERE status = 'TODO' ORDER BY priority DESC")
    suspend fun getAllTodoNodes(): List<NodeEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNode(node: NodeEntity)

    @Query("UPDATE nodes SET status = 'DONE', updatedAt = :timestamp WHERE id = :nodeId")
    suspend fun markDone(nodeId: String, timestamp: Long = System.currentTimeMillis())

    @Query("SELECT * FROM nodes WHERE id = :nodeId")
    suspend fun getNodeById(nodeId: String): NodeEntity?
}

@Dao
interface SessionDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSession(session: SessionEntity)

    @Update
    suspend fun updateSession(session: SessionEntity)

    @Query("UPDATE sessions SET endAt = :endAt, selfReportMin = :selfReportMin, focus = :focus, points = :points WHERE id = :sessionId")
    suspend fun endSession(sessionId: String, endAt: Long, selfReportMin: Int, focus: Int, points: Double)

    @Query("SELECT * FROM sessions WHERE startAt BETWEEN :start AND :end")
    suspend fun getSessionsInRange(start: Long, end: Long): List<SessionEntity>

    @Query("SELECT * FROM sessions WHERE startAt >= :startOfDay")
    suspend fun getSessionsSince(startOfDay: Long): List<SessionEntity>

    @Insert
    suspend fun insertRecoveryEvent(event: RecoveryEventEntity)
    
    @Query("SELECT COALESCE(SUM(points), 0.0) FROM sessions WHERE points IS NOT NULL")
    fun getTotalPointsFlow(): Flow<Double>

    @Query("SELECT * FROM sessions WHERE id = :sessionId LIMIT 1")
    suspend fun getSessionById(sessionId: String): SessionEntity?
}

@Dao
interface AggDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertDailyAgg(agg: DailyAggEntity)

    @Query("SELECT * FROM daily_agg WHERE yyyymmdd = :yyyymmdd")
    suspend fun getAgg(yyyymmdd: Int): DailyAggEntity?
    
    @Query("SELECT * FROM daily_agg ORDER BY yyyymmdd DESC LIMIT :limit")
    fun getAggRange(limit: Int): Flow<List<DailyAggEntity>>
}

@Dao
interface SettingsDao {
    @Query("SELECT * FROM settings WHERE `key` = 'singleton'")
    suspend fun getSettings(): SettingsEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSettings(settings: SettingsEntity)
}

@Dao
interface CampusVisitDao {
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun recordVisit(visit: CampusVisitEntity)

    @Query("SELECT * FROM campus_visits ORDER BY yyyymmdd DESC")
    suspend fun getAllVisits(): List<CampusVisitEntity>
}
