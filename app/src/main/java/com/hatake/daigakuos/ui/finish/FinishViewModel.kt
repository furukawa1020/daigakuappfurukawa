package com.hatake.daigakuos.ui.finish

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.NodeType
import com.hatake.daigakuos.domain.usecase.FinalizeSessionUseCase
import com.hatake.daigakuos.domain.usecase.GetFinishSuggestionsUseCase
import com.hatake.daigakuos.domain.usecase.SessionResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/** Session quality grade (S > A > B > C) based on focus × minutes */
enum class SessionGrade(val label: String, val emoji: String) {
    S("S", "🌟"),
    A("A", "✨"),
    B("B", "👍"),
    C("C", "🙂")
}

fun calcGrade(minutes: Int, focus: Int): SessionGrade {
    val score = minutes * focus
    return when {
        score >= 180 -> SessionGrade.S   // e.g. 60min×3 or 45min×4
        score >= 100 -> SessionGrade.A   // e.g. 25min×4 or 50min×2
        score >= 50  -> SessionGrade.B
        else         -> SessionGrade.C
    }
}

val MOTIVATIONAL_QUOTES = listOf(
    "千里の道も一歩から。また一歩進んだね！",
    "継続は力なり。その積み重ねが未来を作る。",
    "小さな進歩でも、昨日の自分を超えている。",
    "集中できた時間は、誰にも奪えない財産だ。",
    "やり始めたあなたは、すでに勝者。",
    "努力した事実は永遠に消えない。",
    "今日の一歩が、明日の自信になる。",
    "完璧じゃなくていい。続けることが大事。",
    "Moko も一緒に成長してるよ！"
)

data class FinishUiState(
    val suggestions: List<NodeEntity> = emptyList(),
    val isLoading: Boolean = false,
    val sessionResult: SessionResult? = null,
    val grade: SessionGrade? = null,
    val motivationalQuote: String = MOTIVATIONAL_QUOTES.random(),
    val showAchievementCelebration: Boolean = false,
    val celebrationAchievementIds: List<String> = emptyList()
)

@HiltViewModel
class FinishViewModel @Inject constructor(
    private val finalizeSessionUseCase: FinalizeSessionUseCase,
    private val getFinishSuggestionsUseCase: GetFinishSuggestionsUseCase,
    private val soundManager: com.hatake.daigakuos.utils.SoundManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(FinishUiState())
    val uiState: StateFlow<FinishUiState> = _uiState.asStateFlow()

    init {
        loadSuggestions()
    }

    private fun loadSuggestions() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(suggestions = getFinishSuggestionsUseCase())
        }
    }

    fun finalizeSession(
        sessionId: String,
        selectedNodeId: String?,
        newNodeTitle: String?,
        newNodeType: NodeType?,
        minutes: Int,
        focus: Int,
        onSuccess: (SessionResult?) -> Unit
    ) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            val result = finalizeSessionUseCase(
                sessionId = sessionId,
                selectedNodeId = selectedNodeId,
                newNodeTitle = newNodeTitle,
                newNodeType = newNodeType,
                selfReportMin = minutes,
                focus = focus
            )
            val grade = calcGrade(minutes, focus)
            val quote = MOTIVATIONAL_QUOTES.random()

            _uiState.value = _uiState.value.copy(
                isLoading = false,
                sessionResult = result,
                grade = grade,
                motivationalQuote = quote,
                showAchievementCelebration = result?.unlockedAchievements?.isNotEmpty() == true,
                celebrationAchievementIds = result?.unlockedAchievements ?: emptyList()
            )
            soundManager.playSessionComplete()
            onSuccess(result)
        }
    }

    fun dismissAchievementCelebration() {
        _uiState.value = _uiState.value.copy(showAchievementCelebration = false)
    }
}
