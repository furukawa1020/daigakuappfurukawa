package com.hatake.daigakuos.domain.repository

import kotlinx.coroutines.flow.CustomFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

interface UserContextRepository {
    val isOnCampus: StateFlow<Boolean>
    suspend fun setCampusState(isContext: Boolean)
}

@Singleton
class UserContextRepositoryImpl @Inject constructor() : UserContextRepository {
    private val _isOnCampus = MutableStateFlow(false)
    override val isOnCampus: StateFlow<Boolean> = _isOnCampus.asStateFlow()

    override suspend fun setCampusState(isOnCampus: Boolean) {
        _isOnCampus.value = isOnCampus
        // Here we could also persist this to DataStore if we want it to survive process death
        // better than just memory. For now, memory is fine for singleton.
    }
}
