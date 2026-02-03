package com.hatake.daigakuos.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

// Enums
enum class ProjectType {
    STUDY,    // 講義・宿題・学習 (Blue)
    RESEARCH, // 研究 (Purple)
    MAKE,     // 制作 (Red)
    ADMIN     // 事務・手続き (Yellow)
}

enum class NodeStatus {
    TODO,
    DONE
}

enum class Mode {
    DEFAULT,
    CREATIVE, // Research/Make prioritized
    RECOVERY  // Rest prioritized
}

enum class RecoveryType {
    SLEEP,
    NAP,
    WALK,
    BATH,
    EAT,
    SUNLIGHT,
    OTHER
}

// Entities

@Entity(tableName = "projects")
data class ProjectEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    val description: String? = null,
    val type: ProjectType, // Default type for nodes in this project
    val createdAt: Long = System.currentTimeMillis()
)

@Entity(
    tableName = "nodes",
    foreignKeys = [
        ForeignKey(
            entity = ProjectEntity::class,
            parentColumns = ["id"],
            childColumns = ["projectId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = NodeEntity::class,
            parentColumns = ["id"],
            childColumns = ["parentId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("projectId"), Index("parentId")]
)
data class NodeEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val projectId: Long,
    val parentId: Long? = null, // Null = Root of project
    val title: String, // 具体的な作業名 "統計レポ 問2"
    val type: ProjectType, // Inherits from Project usually, but can be overridden? Usually same.
    val status: NodeStatus = NodeStatus.TODO,
    val estimateMinutes: Int = 25, // Default pomodoro size
    val deadline: Long? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val completedAt: Long? = null
)

@Entity(
    tableName = "node_events",
    foreignKeys = [
        ForeignKey(
            entity = NodeEntity::class,
            parentColumns = ["id"],
            childColumns = ["nodeId"],
            onDelete = ForeignKey.SET_NULL
        )
    ],
    indices = [Index("nodeId")]
)
data class NodeEventEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val nodeId: Long?,
    val timestamp: Long = System.currentTimeMillis(),
    
    // User Input
    val actualMinutes: Int, 
    val focusLevel: Int, // 1-5

    // Context (Awareness)
    val isOnCampus: Boolean,

    // Point Calculation Components (Snapshot at time of completion)
    val diversityScore: Float, // Calculated based on recent history
    val recoveryMultiplier: Float, // Calculated based on Recovery/Livelihood status
    val finalPoints: Float // The result: (Trial * Diversity + Awareness) * (Recovery + Livelihood)
)

@Entity(tableName = "recovery_events")
data class RecoveryEventEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val type: RecoveryType,
    val timestamp: Long = System.currentTimeMillis(),
    val note: String? = null
)

@Entity(tableName = "daily_metrics")
data class DailyMetricEntity(
    @PrimaryKey val dateKey: String, // YYYY-MM-DD
    val totalPoints: Float = 0f,
    val studyPoints: Float = 0f,
    val researchPoints: Float = 0f,
    val makePoints: Float = 0f,
    val adminPoints: Float = 0f,
    val nodeCount: Int = 0,
    val maxStreak: Int = 0,
    val isOnCampusDetected: Boolean = false
)
