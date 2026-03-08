package com.hatake.daigakuos.ui.finish

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.*
import androidx.compose.animation.fadeIn
import androidx.compose.animation.scaleIn
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.hatake.daigakuos.data.local.entity.NodeType

// ──────────────────────────────────────────
// Achievement ID → display info
// ──────────────────────────────────────────
private val ACHIEVEMENT_DISPLAY = mapOf(
    "first_session"       to Pair("はじめの一歩", "🎉"),
    "three_day_streak"    to Pair("3日坊主卒業", "🔥"),
    "seven_day_streak"    to Pair("習慣の達人", "🌟"),
    "quick_win"           to Pair("クイックウィン", "⚡"),
    "hyper_focus"         to Pair("ハイパーフォーカス", "🧘"),
    "home_guardian"       to Pair("ホームガーディアン", "🏠"),
    "early_bird"          to Pair("アーリーバード", "🌅"),
    "night_owl"           to Pair("ナイトオウル", "🦉"),
    "total_time_10_hours" to Pair("見習い完了", "⏳")
)

// ──────────────────────────────────────────
// Main FinishScreen
// ──────────────────────────────────────────
@Composable
fun FinishScreen(
    sessionId: String,
    elapsedMinutes: Int,
    onFinish: () -> Unit,
    viewModel: FinishViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val haptic = LocalHapticFeedback.current
    val context = LocalContext.current

    var selectedNodeId by remember { mutableStateOf<String?>(null) }
    var newTaskTitle by remember { mutableStateOf("") }
    var newTaskType by remember { mutableStateOf(NodeType.STUDY) }
    var finalMinutes by remember { mutableIntStateOf(elapsedMinutes) }
    var finalFocus by remember { mutableIntStateOf(3) }

    // Show achievement celebration when badges unlock
    LaunchedEffect(uiState.showAchievementCelebration) {
        if (uiState.showAchievementCelebration) {
            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        }
    }

    // Achievement Celebration Dialog
    if (uiState.showAchievementCelebration) {
        AchievementCelebrationDialog(
            achievementIds = uiState.celebrationAchievementIds,
            onDismiss = { viewModel.dismissAchievementCelebration() }
        )
    }

    Scaffold(
        bottomBar = {
            Surface(
                color = MaterialTheme.colorScheme.surface,
                tonalElevation = 16.dp,
                shape = RoundedCornerShape(topStart = 32.dp, topEnd = 32.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp, vertical = 20.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    OutlinedButton(
                        onClick = {
                            val isNew = selectedNodeId == null && newTaskTitle.isNotBlank()
                            if (selectedNodeId != null || isNew) {
                                viewModel.finalizeSession(
                                    sessionId = sessionId,
                                    selectedNodeId = selectedNodeId,
                                    newNodeTitle = if (isNew) newTaskTitle else null,
                                    newNodeType = if (isNew) newTaskType else null,
                                    minutes = finalMinutes,
                                    focus = finalFocus,
                                    onSuccess = { onFinish() }
                                )
                            } else {
                                onFinish()
                            }
                        },
                        modifier = Modifier.weight(1f).height(56.dp),
                        shape = CircleShape
                    ) {
                        Text("完了のみ", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                    }

                    Button(
                        onClick = {
                            val isNew = selectedNodeId == null && newTaskTitle.isNotBlank()
                            if (selectedNodeId != null || isNew) {
                                viewModel.finalizeSession(
                                    sessionId = sessionId,
                                    selectedNodeId = selectedNodeId,
                                    newNodeTitle = if (isNew) newTaskTitle else null,
                                    newNodeType = if (isNew) newTaskType else null,
                                    minutes = finalMinutes,
                                    focus = finalFocus,
                                    onSuccess = { result ->
                                        if (result != null) {
                                            val shareIntent = com.hatake.daigakuos.utils.ShareUtils.createShareIntent(
                                                context = context,
                                                completedNode = result.node,
                                                pointsGained = result.points.toFloat(),
                                                streak = result.streak,
                                                isOnCampus = result.isOnCampus,
                                                earnedMokoCoins = result.earnedMokoCoins,
                                                earnedStarCrystals = result.earnedStarCrystals,
                                                earnedCampusGems = result.earnedCampusGems
                                            )
                                            context.startActivity(shareIntent)
                                        }
                                        onFinish()
                                    }
                                )
                            }
                        },
                        modifier = Modifier.weight(1.2f).height(56.dp),
                        shape = CircleShape
                    ) {
                        Icon(Icons.Default.Check, "Done")
                        Spacer(Modifier.width(8.dp))
                        Text("完了＆シェア", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .padding(horizontal = 20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
            contentPadding = PaddingValues(vertical = 20.dp)
        ) {
            // ── Section 1: Grade + Quote ──────────────────────
            item {
                SessionResultCard(
                    minutes = finalMinutes,
                    grade = uiState.grade,
                    quote = uiState.motivationalQuote,
                    onMinutesMinus = { if (finalMinutes > 5) finalMinutes -= 5 },
                    onMinutesPlus = { finalMinutes += 5 }
                )
            }

            // ── Section 2: Attribution ────────────────────────
            item {
                Text("何をやりましたか？", style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(
                    value = newTaskTitle,
                    onValueChange = { newTaskTitle = it; selectedNodeId = null },
                    label = { Text("新しい成果 (1行入力)") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp)
                )
                if (newTaskTitle.isNotBlank() && selectedNodeId == null) {
                    Spacer(Modifier.height(8.dp))
                    TypeSelector(selected = newTaskType, onSelect = { newTaskType = it })
                }
            }

            // ── Section 3: Suggestions ────────────────────────
            item {
                Text("履歴から選択", style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.outline)
            }

            items(uiState.suggestions) { node ->
                SuggestionItem(
                    title = node.title,
                    type = node.type,
                    isSelected = selectedNodeId == node.id,
                    onClick = { selectedNodeId = node.id; newTaskTitle = "" }
                )
            }

            // ── Section 4: Focus Slider ───────────────────────
            item {
                Text("集中度: $finalFocus", style = MaterialTheme.typography.titleMedium)
                Slider(
                    value = finalFocus.toFloat(),
                    onValueChange = { finalFocus = it.toInt() },
                    valueRange = 1f..5f,
                    steps = 3
                )
                // Grade preview
                val previewGrade = calcGrade(finalMinutes, finalFocus)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("予測グレード: ", style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.outline)
                    Text("${previewGrade.emoji} ${previewGrade.label}",
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.Bold,
                        color = gradeColor(previewGrade))
                }
            }

            item { Spacer(modifier = Modifier.height(80.dp)) }
        }
    }
}

// ──────────────────────────────────────────
// Session Result Card (Grade + Quote)
// ──────────────────────────────────────────
@Composable
fun SessionResultCard(
    minutes: Int,
    grade: SessionGrade?,
    quote: String,
    onMinutesMinus: () -> Unit,
    onMinutesPlus: () -> Unit
) {
    val infiniteTransition = rememberInfiniteTransition(label = "grade_pulse")
    val pulse by infiniteTransition.animateFloat(
        initialValue = 1f, targetValue = 1.08f,
        animationSpec = infiniteRepeatable(tween(900), RepeatMode.Reverse),
        label = "grade_scale"
    )

    Surface(
        shape = RoundedCornerShape(28.dp),
        color = MaterialTheme.colorScheme.primaryContainer,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("セッション完了！", style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f))

            Spacer(Modifier.height(16.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("$minutes 分", style = MaterialTheme.typography.displayMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onPrimaryContainer)
                Spacer(Modifier.width(16.dp))
                IconButton(onClick = onMinutesMinus) {
                    Text("−", fontSize = 20.sp, color = MaterialTheme.colorScheme.onPrimaryContainer)
                }
                IconButton(onClick = onMinutesPlus) {
                    Text("+", fontSize = 20.sp, color = MaterialTheme.colorScheme.onPrimaryContainer)
                }
            }

            if (grade != null) {
                Spacer(Modifier.height(12.dp))
                AnimatedVisibility(visible = true, enter = fadeIn() + scaleIn()) {
                    Text(
                        text = "${grade.emoji} Grade ${grade.label}",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.ExtraBold,
                        color = gradeColor(grade),
                        modifier = Modifier
                    )
                }
            }

            Spacer(Modifier.height(16.dp))

            Text(
                text = "\"$quote\"",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.85f),
                textAlign = TextAlign.Center,
                fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
            )
        }
    }
}

// ──────────────────────────────────────────
// Achievement Celebration Dialog
// ──────────────────────────────────────────
@Composable
fun AchievementCelebrationDialog(
    achievementIds: List<String>,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        shape = RoundedCornerShape(28.dp),
        title = {
            Text(
                "バッジ獲得！🎊",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        },
        text = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                achievementIds.forEach { id ->
                    val (name, emoji) = ACHIEVEMENT_DISPLAY[id] ?: Pair(id, "🏅")
                    Spacer(Modifier.height(12.dp))
                    Surface(
                        shape = CircleShape,
                        color = MaterialTheme.colorScheme.primaryContainer,
                        modifier = Modifier.size(80.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text(emoji, fontSize = 40.sp)
                        }
                    }
                    Spacer(Modifier.height(8.dp))
                    Text(name, style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center)
                }
                Spacer(Modifier.height(12.dp))
                Text("実績ギャラリーで確認できるよ！",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                    textAlign = TextAlign.Center)
            }
        },
        confirmButton = {
            Button(onClick = onDismiss, shape = CircleShape,
                modifier = Modifier.fillMaxWidth()) {
                Text("やった！")
            }
        }
    )
}

// ──────────────────────────────────────────
// Grade color helper
// ──────────────────────────────────────────
@Composable
fun gradeColor(grade: SessionGrade): Color = when (grade) {
    SessionGrade.S -> Color(0xFFFFD700)  // Gold
    SessionGrade.A -> Color(0xFF4CAF50)  // Green
    SessionGrade.B -> Color(0xFF2196F3)  // Blue
    SessionGrade.C -> Color(0xFF9E9E9E)  // Grey
}

// ──────────────────────────────────────────
// TypeSelector
// ──────────────────────────────────────────
@Composable
fun TypeSelector(selected: NodeType, onSelect: (NodeType) -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        NodeType.values().forEach { type ->
            FilterChip(
                selected = selected == type,
                onClick = { onSelect(type) },
                label = { Text(type.name) }
            )
        }
    }
}

// ──────────────────────────────────────────
// SuggestionItem
// ──────────────────────────────────────────
@Composable
fun SuggestionItem(title: String, type: String, isSelected: Boolean, onClick: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable { onClick() },
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer
            else MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Text(title, style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(4.dp))
            Text(type, style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.secondary)
        }
    }
}
