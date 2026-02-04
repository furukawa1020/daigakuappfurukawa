package com.hatake.daigakuos.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

// Enums
enum class NodeType {
    STUDY,    // 講義・宿題・学習
    RESEARCH, // 研究
    MAKE,     // 制作
    ADMIN     // 事務・手続き
}

enum class Mode {
    DEFAULT,
    CREATIVE, // Research/Make prioritized
    RECOVERY  // Rest prioritized
}

enum class NodeStatus {
    TODO,
    DOING,
    DONE,
    ARCHIVED
}

// 2.1 Project（大分類）
@Entity(tableName = "projects")
data class ProjectEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val title: String,
    val orderIndex: Int = 0,
    val createdAt: Long = System.currentTimeMillis()
)

// 2.2 Node（成果ノード。ツリー構造）
@Entity(
    tableName = "nodes",
    foreignKeys = [
        ForeignKey(
            entity = ProjectEntity::class,
            parentColumns = ["id"],
            childColumns = ["projectId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("projectId"), Index("parentId"), Index("type"), Index("status")]
)
data class NodeEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val projectId: String,
    val parentId: String? = null,       // ツリー
    val title: String,                  // 具体名
    val type: String,                   // NodeType.name
    val status: String = "TODO",        // NodeStatus.name
    val deadlineAt: Long? = null,
    val estimateMin: Int? = null,       // 任意
    val priority: Int = 0,              // 任意
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)

// 2.3 Session（実行ログ：開始→完了/中断）
@Entity(
    tableName = "sessions",
    indices = [Index("nodeId"), Index("startAt"), Index("mode"), Index("points")]
)
data class SessionEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val nodeId: String? = null,         // Nullable for "Unspecified"
    val draftTitle: String? = null,     // For ad-hoc sessions
    val mode: String,                   // Mode.name
    val startAt: Long = System.currentTimeMillis(),
    val endAt: Long? = null,
    val selfReportMin: Int? = null,      // 10/25/50/90...
    val focus: Int? = null,              // 1..5
    val onCampus: Boolean = false,
    val points: Double? = null,          // 完了時に確定
    val finalizedAt: Long? = null        // 確定時刻
)

// 2.4 Recovery（回復ノード：簡易でもOK）
@Entity(
    tableName = "recovery_events", 
    indices = [Index("startAt")]
)
data class RecoveryEventEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val kind: String,                // "sleep","walk","bath","meal","sun"...
    val startAt: Long = System.currentTimeMillis(),
    val endAt: Long? = null,
    val selfReportMin: Int? = null
)

// 2.5 Settings（単一行）
@Entity(tableName = "settings")
data class SettingsEntity(
    @PrimaryKey val key: String = "singleton",
    val weeklyHourTarget: Int = 40,
    val campusLat: Double = 36.5447, // Default Kanazawa Univ
    val campusLng: Double = 136.6963,
    val campusRadiusM: Float = 120f,
    val campusBaseMultiplier: Double = 1.6,   // 大学内倍率
    val streakCapMultiplier: Double = 1.3,    // 連続上限
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)

// 2.6 DailyAgg（草・タンクの高速表示用キャッシュ）
@Entity(tableName = "daily_agg")
data class DailyAggEntity(
    @PrimaryKey val yyyymmdd: Int,  // 例: 20260203
    val pointsTotal: Double = 0.0,
    val countDone: Int = 0,
    val pointsStudy: Double = 0.0,
    val pointsResearch: Double = 0.0,
    val pointsMake: Double = 0.0,
    val pointsAdmin: Double = 0.0,
    val minutesSelfReport: Int = 0
)

// 5. 連続通学記録
@Entity(tableName="campus_visits")
data class CampusVisitEntity(
  @PrimaryKey val yyyymmdd: Int
)
