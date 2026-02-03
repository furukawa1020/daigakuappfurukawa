package com.hatake.daigakuos.di

import com.hatake.daigakuos.data.repository.NodeRepositoryImpl
import com.hatake.daigakuos.domain.repository.NodeRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    abstract fun bindNodeRepository(
        impl: NodeRepositoryImpl
    ): NodeRepository

    // StatsRepository binding would go here too if implemented
}
