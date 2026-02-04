package com.hatake.daigakuos.di

import android.content.Context
import androidx.room.Room
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

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "daigaku_os.db"
        )
        // Database Migration Strategy:
        // - Version 2 is the first production version (no migration from v1 needed)
        // - When adding new versions, define migrations in Migrations.kt
        // - Add migrations here using .addMigrations(MIGRATION_X_Y)
        // 
        // Example for future v3:
        // .addMigrations(MIGRATION_2_3)
        //
        // IMPORTANT: We do NOT use .fallbackToDestructiveMigration()
        // This ensures the app will crash (fail-fast) if a migration is missing,
        // rather than silently deleting all user data. This is intentional to
        // protect user data and force developers to implement proper migrations.
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
