package com.hatake.daigakuos.utils

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import com.hatake.daigakuos.R
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SoundManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val userSettingsRepository: com.hatake.daigakuos.domain.repository.UserSettingsRepository
) {
    private var soundPool: SoundPool? = null
    
    private var clickSoundId: Int = 0
    private var completeSoundId: Int = 0
    private var levelUpSoundId: Int = 0

    private val _isSoundEnabled = MutableStateFlow(true)
    val isSoundEnabled: StateFlow<Boolean> = _isSoundEnabled.asStateFlow()
    
    // We assume sounds are loaded async. Keeping it simple for now.
    init {
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        soundPool = SoundPool.Builder()
            .setMaxStreams(3)
            .setAudioAttributes(audioAttributes)
            .build()
            
        soundPool?.let { pool ->
            try {
                clickSoundId = pool.load(context, R.raw.ui_click, 1)
                completeSoundId = pool.load(context, R.raw.session_complete, 1)
                levelUpSoundId = pool.load(context, R.raw.level_up, 1)
            } catch (e: Exception) {
                // If files are dummy or missing, it might throw, so we catch it
            }
        }
        
        kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO).launch {
            userSettingsRepository.isSoundEnabledFlow.collect { enabled ->
                _isSoundEnabled.value = enabled
            }
        }
    }

    fun setSoundEnabled(enabled: Boolean) {
        _isSoundEnabled.value = enabled
    }

    fun playClick() {
        if (!_isSoundEnabled.value) return
        soundPool?.play(clickSoundId, 1f, 1f, 1, 0, 1f)
    }

    fun playSessionComplete() {
        if (!_isSoundEnabled.value) return
        soundPool?.play(completeSoundId, 1f, 1f, 2, 0, 1f)
    }

    fun playLevelUp() {
        if (!_isSoundEnabled.value) return
        soundPool?.play(levelUpSoundId, 1f, 1f, 3, 0, 1f)
    }

    fun release() {
        soundPool?.release()
        soundPool = null
    }
}
