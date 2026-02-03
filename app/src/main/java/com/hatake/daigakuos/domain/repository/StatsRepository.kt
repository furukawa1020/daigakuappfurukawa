package com.hatake.daigakuos.domain.repository

import com.hatake.daigakuos.data.local.entity.ProjectType

interface StatsRepository {
    suspend fun getTodayCompletedTypes(): List<ProjectType>
    suspend fun getRecentRecoveryCount(): Int
    suspend fun getStreak(): Int
}
