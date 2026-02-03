package com.hatake.daigakuos.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.hatake.daigakuos.data.local.dao.*
import com.hatake.daigakuos.data.local.entity.*

@Database(
    entities = [
        ProjectEntity::class,
        NodeEntity::class, 
        SessionEntity::class, 
        RecoveryEventEntity::class, 
        DailyAggEntity::class,
        SettingsEntity::class,
        CampusVisitEntity::class
    ],
    version = 2,
    exportSchema = false
)
// @androidx.room.TypeConverters(Converters::class) // Removed, using primitive types (String, Long)
abstract class AppDatabase : RoomDatabase() {
    abstract fun projectDao(): ProjectDao
    abstract fun nodeDao(): NodeDao
    abstract fun sessionDao(): SessionDao
    abstract fun aggDao(): AggDao
    abstract fun settingsDao(): SettingsDao
    abstract fun campusVisitDao(): CampusVisitDao
}
