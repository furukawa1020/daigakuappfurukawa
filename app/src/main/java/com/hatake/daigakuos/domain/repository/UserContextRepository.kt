package com.hatake.daigakuos.domain.repository

import kotlinx.coroutines.flow.StateFlow

import com.hatake.daigakuos.data.local.entity.Mode

interface UserContextRepository {
    val isOnCampus: StateFlow<Boolean>
    val currentMode: StateFlow<Mode>
    suspend fun setCampusState(isContext: Boolean)
    suspend fun setMode(mode: Mode)
}
