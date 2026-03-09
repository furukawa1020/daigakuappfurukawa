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
        CampusVisitEntity::class,
        WalletEntity::class,
        WeeklyChallengeEntity::class,
        AchievementEntity::class
    ],
    version = 6,
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
    abstract fun walletDao(): WalletDao
    abstract fun weeklyChallengeDao(): WeeklyChallengeDao
    abstract fun achievementDao(): AchievementDao

    companion object {
        @Volatile private var INSTANCE: AppDatabase? = null

        fun getInstance(context: android.content.Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: androidx.room.Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "daigaku_os.db"
                )
                    .addMigrations(
                        com.hatake.daigakuos.data.local.MIGRATION_2_3,
                        com.hatake.daigakuos.data.local.MIGRATION_3_4,
                        com.hatake.daigakuos.data.local.MIGRATION_4_5,
                        com.hatake.daigakuos.data.local.MIGRATION_5_6
                    )
                    .fallbackToDestructiveMigration()
                    .build().also { INSTANCE = it }
            }
        }
    }
}
