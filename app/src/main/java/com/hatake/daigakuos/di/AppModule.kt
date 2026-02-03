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
        ).build()
    }

    @Provides
    fun provideProjectDao(db: AppDatabase): ProjectDao = db.projectDao()

    @Provides
    fun provideNodeDao(db: AppDatabase): NodeDao = db.nodeDao()

    @Provides
    fun provideEventDao(db: AppDatabase): EventDao = db.eventDao()
    
    @Provides
    fun provideDailyMetricDao(db: AppDatabase): DailyMetricDao = db.dailyMetricDao()

    // Repositories
    // Ideally we bind interface to impl using @Binds, but for quick setup:
    
    @Provides
    @Singleton
    fun provideUserContextRepository(): UserContextRepository {
        return UserContextRepositoryImpl()
    }

    @Provides
    @Singleton
    fun provideNodeRepository(nodeDao: NodeDao): com.hatake.daigakuos.domain.repository.NodeRepository {
        return com.hatake.daigakuos.data.repository.NodeRepositoryImpl(nodeDao)
    }

    @Provides
    @Singleton
    fun provideStatsRepository(eventDao: EventDao, dailyMetricDao: DailyMetricDao): com.hatake.daigakuos.domain.repository.StatsRepository {
        return com.hatake.daigakuos.data.repository.StatsRepositoryImpl(eventDao, dailyMetricDao)
    }
    
    // Note: NodeRepository and StatsRepository need implementations too.
    // Since we only defined interfaces in domain, we need Impls.
    // I will assume for MVP we might just use the DAOs directly in UseCases OR I need to write the Impl files quickly.
    // Let's rely on standard Hilt pattern: If UseCase needs NodeRepository, we must provide NodeRepository.
}
