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

    @Update
    suspend fun updateNode(node: NodeEntity)

    @Query("SELECT * FROM nodes WHERE status != 'ARCHIVED' AND status != 'DONE'")
    fun getActiveNodes(): Flow<List<NodeEntity>>

    @Query("SELECT * FROM nodes WHERE projectId = :projectId AND (parentId = :parentId OR (:parentId IS NULL AND parentId IS NULL))")
    fun getNodesByParent(projectId: String, parentId: String?): Flow<List<NodeEntity>>
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
    
    @Query("SELECT COALESCE(SUM(points), 0.0) FROM sessions")
    fun getTotalPointsFlow(): Flow<Double>

    @Query("SELECT COALESCE(SUM(points), 0.0) FROM sessions")
    suspend fun getTotalPoints(): Double

    @Query("SELECT COUNT(*) FROM sessions")
    suspend fun getSessionCount(): Int

    @Query("SELECT * FROM sessions WHERE id = :sessionId LIMIT 1")
    suspend fun getSessionById(sessionId: String): SessionEntity?

    @Query("SELECT * FROM sessions ORDER BY startAt DESC LIMIT 50")
    fun getRecentSessions(): Flow<List<SessionEntity>>

    @Delete
    suspend fun deleteSession(session: SessionEntity)
}

@Dao
interface AggDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertDailyAgg(agg: DailyAggEntity)

    @Query("SELECT * FROM daily_agg WHERE yyyymmdd = :yyyymmdd")
    suspend fun getAgg(yyyymmdd: Int): DailyAggEntity?
    
    @Query("SELECT * FROM daily_agg ORDER BY yyyymmdd DESC LIMIT :limit")
    fun getAggRange(limit: Int): Flow<List<DailyAggEntity>>

    /** Returns all days that had at least one completed session, sorted newest-first */
    @Query("SELECT * FROM daily_agg WHERE countDone > 0 ORDER BY yyyymmdd DESC")
    suspend fun getActiveDaysDesc(): List<DailyAggEntity>

    @Query("SELECT * FROM daily_agg WHERE yyyymmdd BETWEEN :start AND :end")
    suspend fun getAggsInRange(start: Int, end: Int): List<DailyAggEntity>
    
    /**
     * Atomically add study points to the daily aggregate.
     * @return Number of rows affected (1 if successful, 0 if row doesn't exist)
     */
    @Query("""
        UPDATE daily_agg 
        SET pointsTotal = pointsTotal + :points,
            pointsStudy = pointsStudy + :points,
            countDone = countDone + 1,
            minutesSelfReport = minutesSelfReport + :minutes
        WHERE yyyymmdd = :yyyymmdd
    """)
    suspend fun addStudyPoints(yyyymmdd: Int, points: Double, minutes: Int): Int
    
    /**
     * Atomically add research points to the daily aggregate.
     * @return Number of rows affected (1 if successful, 0 if row doesn't exist)
     */
    @Query("""
        UPDATE daily_agg 
        SET pointsTotal = pointsTotal + :points,
            pointsResearch = pointsResearch + :points,
            countDone = countDone + 1,
            minutesSelfReport = minutesSelfReport + :minutes
        WHERE yyyymmdd = :yyyymmdd
    """)
    suspend fun addResearchPoints(yyyymmdd: Int, points: Double, minutes: Int): Int
    
    /**
     * Atomically add make points to the daily aggregate.
     * @return Number of rows affected (1 if successful, 0 if row doesn't exist)
     */
    @Query("""
        UPDATE daily_agg 
        SET pointsTotal = pointsTotal + :points,
            pointsMake = pointsMake + :points,
            countDone = countDone + 1,
            minutesSelfReport = minutesSelfReport + :minutes
        WHERE yyyymmdd = :yyyymmdd
    """)
    suspend fun addMakePoints(yyyymmdd: Int, points: Double, minutes: Int): Int
    
    /**
     * Atomically add admin points to the daily aggregate.
     * @return Number of rows affected (1 if successful, 0 if row doesn't exist)
     */
    @Query("""
        UPDATE daily_agg 
        SET pointsTotal = pointsTotal + :points,
            pointsAdmin = pointsAdmin + :points,
            countDone = countDone + 1,
            minutesSelfReport = minutesSelfReport + :minutes
        WHERE yyyymmdd = :yyyymmdd
    """)
    suspend fun addAdminPoints(yyyymmdd: Int, points: Double, minutes: Int): Int
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

@Dao
interface WeeklyChallengeDao {
    @Query("SELECT * FROM weekly_challenges WHERE yearWeek = :yearWeek")
    fun getChallengesForWeek(yearWeek: String): Flow<List<WeeklyChallengeEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertChallenge(challenge: WeeklyChallengeEntity)
    
    @Update
    suspend fun updateChallenge(challenge: WeeklyChallengeEntity)
}

@Dao
interface AchievementDao {
    @Query("SELECT * FROM user_achievements ORDER BY unlockedAt DESC")
    fun getAllAchievements(): Flow<List<AchievementEntity>>

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun unlockAchievement(achievement: AchievementEntity): Long // Returns -1 if already exists

    @Query("UPDATE user_achievements SET isNew = 0 WHERE isNew = 1")
    suspend fun markAllAsViewed()
    
    @Query("SELECT COUNT(*) FROM user_achievements")
    suspend fun getUnlockedCount(): Int
}
