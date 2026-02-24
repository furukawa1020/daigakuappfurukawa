package com.hatake.daigakuos.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.dao.SettingsDao
import com.hatake.daigakuos.data.local.entity.SettingsEntity
import com.hatake.daigakuos.domain.repository.ThemePreference
import com.hatake.daigakuos.domain.repository.UserSettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SettingsUiState(
    val weeklyHourTarget: Int = 40,
    val campusLat: Double = 36.5447,
    val campusLng: Double = 136.6963,
    val campusRadiusM: Float = 120f,
    val isLoading: Boolean = true,
    val themePreference: ThemePreference = ThemePreference.SYSTEM,
    val isSoundEnabled: Boolean = true
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsDao: SettingsDao,
    private val userSettingsRepository: UserSettingsRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        loadSettings()
        observePreferences()
    }

    private fun observePreferences() {
        viewModelScope.launch {
            userSettingsRepository.themePreferenceFlow.collect { theme ->
                _uiState.value = _uiState.value.copy(themePreference = theme)
            }
        }
        viewModelScope.launch {
            userSettingsRepository.isSoundEnabledFlow.collect { enabled ->
                _uiState.value = _uiState.value.copy(isSoundEnabled = enabled)
            }
        }
    }

    private fun loadSettings() {
        viewModelScope.launch {
            val settings = settingsDao.getSettings()
            if (settings != null) {
                _uiState.value = _uiState.value.copy(
                    weeklyHourTarget = settings.weeklyHourTarget,
                    campusLat = settings.campusLat,
                    campusLng = settings.campusLng,
                    campusRadiusM = settings.campusRadiusM,
                    isLoading = false
                )
            } else {
                // Initialize Default
                val default = SettingsEntity()
                settingsDao.insertSettings(default)
                _uiState.value = _uiState.value.copy(isLoading = false)
            }
        }
    }

    fun saveThemePreference(theme: ThemePreference) {
        viewModelScope.launch {
            userSettingsRepository.setThemePreference(theme)
        }
    }

    fun toggleSoundEnabled(enabled: Boolean) {
        viewModelScope.launch {
            userSettingsRepository.setSoundEnabled(enabled)
        }
    }

    fun saveSettings(
        lat: Double,
        lng: Double,
        radius: Float,
        target: Int
    ) {
        viewModelScope.launch {
            val current = settingsDao.getSettings() ?: SettingsEntity()
            val updated = current.copy(
                campusLat = lat,
                campusLng = lng,
                campusRadiusM = radius,
                weeklyHourTarget = target,
                updatedAt = System.currentTimeMillis()
            )
            settingsDao.insertSettings(updated)
            
            // update state
            _uiState.value = _uiState.value.copy(
                weeklyHourTarget = target,
                campusLat = lat,
                campusLng = lng,
                campusRadiusM = radius,
                isLoading = false
            )
        }
    }
}
