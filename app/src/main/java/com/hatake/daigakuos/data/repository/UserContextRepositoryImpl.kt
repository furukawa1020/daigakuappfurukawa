package com.hatake.daigakuos.data.repository

import com.hatake.daigakuos.domain.repository.UserContextRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton



@Singleton
class UserContextRepositoryImpl @Inject constructor() : UserContextRepository {
    private val _isOnCampus = MutableStateFlow(false)
    override val isOnCampus: StateFlow<Boolean> = _isOnCampus.asStateFlow()

    private val _currentMode = MutableStateFlow(com.hatake.daigakuos.data.local.entity.Mode.DEFAULT)
    override val currentMode: StateFlow<com.hatake.daigakuos.data.local.entity.Mode> = _currentMode.asStateFlow()

    override suspend fun setCampusState(isOnCampus: Boolean) {
        _isOnCampus.value = isOnCampus
    }

    override suspend fun setMode(mode: com.hatake.daigakuos.data.local.entity.Mode) {
        _currentMode.value = mode
    }
}
