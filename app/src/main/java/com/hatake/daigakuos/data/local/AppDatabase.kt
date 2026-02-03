package com.hatake.daigakuos.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.hatake.daigakuos.data.local.dao.*
import com.hatake.daigakuos.data.local.entity.*

@Database(
    entities = [
        ProjectEntity::class,
        NodeEntity::class, 
        NodeEventEntity::class, 
        RecoveryEventEntity::class, 
        DailyMetricEntity::class
    ],
    version = 1,
    exportSchema = false
)
@androidx.room.TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun projectDao(): ProjectDao
    abstract fun nodeDao(): NodeDao
    abstract fun eventDao(): EventDao
    abstract fun dailyMetricDao(): DailyMetricDao
}
