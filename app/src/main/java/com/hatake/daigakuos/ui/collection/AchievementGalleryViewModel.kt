package com.hatake.daigakuos.ui.collection

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.dao.AchievementDao
import com.hatake.daigakuos.data.local.entity.AchievementEntity
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AchievementUiItem(
    val id: String,
    val title: String,
    val description: String,
    val emoji: String,
    val isUnlocked: Boolean,
    val isNew: Boolean
)

@HiltViewModel
class AchievementGalleryViewModel @Inject constructor(
    private val achievementDao: AchievementDao
) : ViewModel() {

    private val _uiState = MutableStateFlow<List<AchievementUiItem>>(emptyList())
    val uiState: StateFlow<List<AchievementUiItem>> = _uiState.asStateFlow()

    // Definition of all possible achievements
    private val allAchievementsDef = listOf(
        AchievementDef("first_session", "はじめの一歩", "初めてのセッションを完了する", "🎉"),
        AchievementDef("three_day_streak", "3日坊主卒業", "3日連続でセッションを完了する", "🔥"),
        AchievementDef("seven_day_streak", "習慣の達人", "7日連続でセッションを完了する", "🌟"),
        AchievementDef("quick_win", "クイックウィン", "5分以下の短いセッションを完了する", "⚡"),
        AchievementDef("hyper_focus", "ハイパーフォーカス", "60分以上のセッションを完了する", "🧘"),
        AchievementDef("home_guardian", "ホームガーディアン", "自宅で25分以上のセッションを完了する", "🏠"),
        AchievementDef("early_bird", "アーリーバード", "朝4時〜8時の間にセッションを開始する", "🌅"),
        AchievementDef("night_owl", "ナイトオウル", "夜22時〜深夜3時の間にセッションを開始する", "🦉"),
        AchievementDef("total_time_10_hours", "見習い完了", "累計で10時間(6000pts)以上のフォーカスを達成する", "⏳")
    )

    init {
        viewModelScope.launch {
            achievementDao.getAllAchievements().collect { unlockedEntities ->
                val unlockedMap = unlockedEntities.associateBy { it.id }
                
                val items = allAchievementsDef.map { def ->
                    val unlockedEntity = unlockedMap[def.id]
                    AchievementUiItem(
                        id = def.id,
                        title = def.title,
                        description = def.description,
                        emoji = def.emoji,
                        isUnlocked = unlockedEntity != null,
                        isNew = unlockedEntity?.isNew ?: false
                    )
                }
                
                _uiState.value = items
            }
        }
    }

    fun markAllAsViewed() {
        viewModelScope.launch {
            achievementDao.markAllAsViewed()
        }
    }

    private data class AchievementDef(
        val id: String,
        val title: String,
        val description: String,
        val emoji: String
    )
}
