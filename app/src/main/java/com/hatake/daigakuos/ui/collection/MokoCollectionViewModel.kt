package com.hatake.daigakuos.ui.collection

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.dao.WalletDao
import com.hatake.daigakuos.data.local.entity.WalletEntity
import com.hatake.daigakuos.domain.repository.UserSettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject
import kotlin.random.Random

data class MokoItem(
    val id: String,
    val name: String,
    val emoji: String,
    val isUnlocked: Boolean = false
)

data class MokoCollectionUiState(
    val mokoCoins: Int = 0,
    val collection: List<MokoItem> = emptyList()
)

@HiltViewModel
class MokoCollectionViewModel @Inject constructor(
    private val walletDao: WalletDao,
    private val userSettingsRepository: UserSettingsRepository
) : ViewModel() {

    private val ALL_MOKO_ITEMS = listOf(
        MokoItem("moko_1", "マシュマロモコ", "🍡"),
        MokoItem("moko_2", "コーヒーモコ", "☕"),
        MokoItem("moko_3", "本モコ", "📘"),
        MokoItem("moko_4", "ねむり猫", "🐈"),
        MokoItem("moko_5", "パンケーキ", "🥞"),
        MokoItem("moko_6", "月うさぎ", "🐇"),
        MokoItem("moko_7", "スター", "⭐"),
        MokoItem("moko_8", "炎モコ", "🔥"),
        MokoItem("moko_9", "さくらモコ", "🌸")
    )

    val uiState: StateFlow<MokoCollectionUiState> = combine(
        walletDao.getWallet().map { it ?: WalletEntity() },
        userSettingsRepository.unlockedMokoItemsFlow
    ) { wallet, unlockedIds ->
        MokoCollectionUiState(
            mokoCoins = wallet.mokoCoins,
            collection = ALL_MOKO_ITEMS.map { item ->
                item.copy(isUnlocked = unlockedIds.contains(item.id))
            }
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = MokoCollectionUiState()
    )

    fun pullGacha() {
        viewModelScope.launch {
            val currentState = uiState.value
            if (currentState.mokoCoins >= 10) {
                walletDao.addMokoCoins(-10)
                // Random pool
                val roll = Random.nextInt(ALL_MOKO_ITEMS.size)
                val newItem = ALL_MOKO_ITEMS[roll]
                userSettingsRepository.unlockMokoItem(newItem.id)
            }
        }
    }
}
