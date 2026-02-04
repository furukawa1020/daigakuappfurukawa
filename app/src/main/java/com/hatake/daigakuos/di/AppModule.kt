package com.hatake.daigakuos.di

import android.content.Context
import androidx.room.Room
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.hatake.daigakuos.data.local.AppDatabase
import com.hatake.daigakuos.data.local.dao.*
import com.hatake.daigakuos.data.repository.UserContextRepositoryImpl
import com.hatake.daigakuos.domain.repository.UserContextRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    // Migration from version 1 to 2: Add campus_visits table
    private val MIGRATION_1_2 = object : Migration(1, 2) {
        override fun migrate(database: SupportSQLiteDatabase) {
            // Create campus_visits table for tracking campus visit streaks
            database.execSQL(
                """
                CREATE TABLE campus_visits (
                    yyyymmdd INTEGER NOT NULL PRIMARY KEY
                )
                """.trimIndent()
            )
        }
    }

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "daigaku_os.db"
        )
        .addMigrations(MIGRATION_1_2)
        .build()
    }

    @Provides
    fun provideProjectDao(db: AppDatabase): ProjectDao = db.projectDao()

    @Provides
    fun provideNodeDao(db: AppDatabase): NodeDao = db.nodeDao()

    @Provides
    fun provideSessionDao(db: AppDatabase): SessionDao = db.sessionDao()
    
    @Provides
    fun provideAggDao(db: AppDatabase): AggDao = db.aggDao()

    @Provides
    fun provideSettingsDao(db: AppDatabase): SettingsDao = db.settingsDao()

    @Provides
    fun provideCampusVisitDao(db: AppDatabase): CampusVisitDao = db.campusVisitDao()

    // Repositories
    @Provides
    @Singleton
    fun provideUserContextRepository(impl: UserContextRepositoryImpl): UserContextRepository {
        return impl
    }
}
