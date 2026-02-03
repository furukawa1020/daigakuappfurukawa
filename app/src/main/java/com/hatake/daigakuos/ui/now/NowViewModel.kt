package com.hatake.daigakuos.ui.now

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.domain.repository.StatsRepository
import com.hatake.daigakuos.domain.repository.UserContextRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class NowViewModel @Inject constructor(
    private val statsRepository: StatsRepository,
    private val userContextRepository: UserContextRepository
) : ViewModel() {

    fun completeSession(nodeId: Long, durationMillis: Long, onComplete: () -> Unit) {
        viewModelScope.launch {
            val isOnCampus = userContextRepository.isOnCampus.value
            val multiplier = if (isOnCampus) 1.5f else 1.0f
            
            // 1 min = 10 pts (MVP base rate)
            val minutes = (durationMillis / 1000 / 60).coerceAtLeast(1)
            val points = minutes * 10 * multiplier
            
            statsRepository.logSession(nodeId, durationMillis, points)
            onComplete()
        }
    }
}
