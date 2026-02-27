package com.hatake.daigakuos.domain.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

enum class ThemePreference {
    SYSTEM, LIGHT, DARK, SAKURA, OCEAN
}

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "user_settings")

class UserSettingsRepository(private val context: Context) {

    private val THEME_KEY = stringPreferencesKey("theme_preference")
    private val SOUND_KEY = androidx.datastore.preferences.core.booleanPreferencesKey("sound_enabled")

    val themePreferenceFlow: Flow<ThemePreference> = context.dataStore.data
        .map { preferences ->
            val themeName = preferences[THEME_KEY] ?: ThemePreference.SYSTEM.name
            try {
                ThemePreference.valueOf(themeName)
            } catch (e: IllegalArgumentException) {
                ThemePreference.SYSTEM
            }
        }

    val isSoundEnabledFlow: Flow<Boolean> = context.dataStore.data
        .map { preferences ->
            preferences[SOUND_KEY] ?: true // Sound enabled by default
        }

    suspend fun setThemePreference(theme: ThemePreference) {
        context.dataStore.edit { preferences ->
            preferences[THEME_KEY] = theme.name
        }
    }

    suspend fun setSoundEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[SOUND_KEY] = enabled
        }
    }

    private val UNLOCKED_MOKO_KEY = androidx.datastore.preferences.core.stringSetPreferencesKey("unlocked_moko_items")

    val unlockedMokoItemsFlow: Flow<Set<String>> = context.dataStore.data
        .map { preferences ->
            preferences[UNLOCKED_MOKO_KEY] ?: emptySet()
        }

    suspend fun unlockMokoItem(itemId: String) {
        context.dataStore.edit { preferences ->
            val current = preferences[UNLOCKED_MOKO_KEY] ?: emptySet()
            preferences[UNLOCKED_MOKO_KEY] = current + itemId
        }
    }
}
