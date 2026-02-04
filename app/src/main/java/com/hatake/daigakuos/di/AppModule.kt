package com.hatake.daigakuos.di

import android.content.Context
import androidx.room.Room
import com.hatake.daigakuos.data.local.AppDatabase
import com.hatake.daigakuos.data.local.MIGRATION_1_2
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
        // Add migrations instead of using destructive migration
        // This ensures user data is preserved across app updates
        .addMigrations(MIGRATION_1_2)
        // Removed .fallbackToDestructiveMigration() to prevent data loss
        // If a migration is missing, the app will crash (fail-fast)
        // which is better than silently deleting user data
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
