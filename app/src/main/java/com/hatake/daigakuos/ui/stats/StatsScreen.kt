package com.hatake.daigakuos.ui.stats

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.LazyHorizontalGrid
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.hatake.daigakuos.data.local.entity.DailyAggEntity
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StatsScreen(
    onBack: () -> Unit,
    viewModel: StatsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var editingSession by remember { mutableStateOf<com.hatake.daigakuos.data.local.entity.SessionEntity?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("箱庭 & 生物") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "戻る")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp)
                .fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // 1. Organism Visualization
            CreatureCard(uiState.creatureStage, uiState.totalPoints)
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // 2. Grass (Contribution Graph)
            Text(
                "活動記録 (過去365日)", 
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.align(Alignment.Start)
            )
            Spacer(modifier = Modifier.height(8.dp))
            
            GrassGrid(uiState.dailyAggs)
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // 3. Recent History (Editable)
            Text(
                "履歴 (タップで編集)",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.align(Alignment.Start)
            )
            Spacer(modifier = Modifier.height(8.dp))
            
            SessionHistoryList(
                sessions = uiState.recentSessions,
                onSessionClick = { session ->
                    // Show Edit Dialog
                    editingSession = session
                }
            )
        }
        
        if (editingSession != null) {
            EditSessionDialog(
                session = editingSession!!,
                onDismiss = { editingSession = null },
                onUpdate = { newTitle ->
                    viewModel.updateSessionTitle(editingSession!!.id, newTitle)
                    editingSession = null
                },
                onDelete = {
                    viewModel.deleteSession(editingSession!!.id)
                    editingSession = null
                }
            )
        }
    }
}

@Composable
fun SessionHistoryList(
    sessions: List<com.hatake.daigakuos.data.local.entity.SessionEntity>,
    onSessionClick: (com.hatake.daigakuos.data.local.entity.SessionEntity) -> Unit
) {
    androidx.compose.foundation.lazy.LazyColumn(
        modifier = Modifier.fillMaxWidth().height(300.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(sessions) { session ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                onClick = { onSessionClick(session) },
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = session.draftTitle?.ifBlank { "名称未設定" } ?: "名称未設定",
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = "${session.selfReportMin ?: 0}分 · ${String.format("%.1f", session.points ?: 0.0)} pts",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.Gray
                        )
                    }
                    val dateStr = java.time.Instant.ofEpochMilli(session.startAt)
                        .atZone(java.time.ZoneId.systemDefault())
                        .format(DateTimeFormatter.ofPattern("MM/dd HH:mm"))
                    Text(text = dateStr, style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditSessionDialog(
    session: com.hatake.daigakuos.data.local.entity.SessionEntity,
    onDismiss: () -> Unit,
    onUpdate: (String) -> Unit,
    onDelete: () -> Unit
) {
    var title by remember { mutableStateOf(session.draftTitle ?: "") }
    var showDeleteConfirm by remember { mutableStateOf(false) }

    if (showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            title = { Text("削除しますか？") },
            text = { Text("この操作は取り消せません。") },
            confirmButton = {
                TextButton(
                    onClick = onDelete,
                    colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)
                ) {
                    Text("削除")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirm = false }) {
                    Text("キャンセル")
                }
            }
        )
    } else {
        AlertDialog(
            onDismissRequest = onDismiss,
            title = { Text("セッション編集") },
            text = {
                Column {
                    OutlinedTextField(
                        value = title,
                        onValueChange = { title = it },
                        label = { Text("タイトル") },
                        singleLine = true
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = { onUpdate(title) }) {
                    Text("保存")
                }
            },
            dismissButton = {
                Row {
                    TextButton(
                        onClick = { showDeleteConfirm = true },
                        colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)
                    ) {
                        Text("削除")
                    }
                    TextButton(onClick = onDismiss) {
                        Text("キャンセル")
                    }
                }
            }
        )
    }
}

@Composable
fun CreatureCard(stage: CreatureStage, points: Double) {
    Card(
        modifier = Modifier
            .size(240.dp)
            .padding(8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
    ) {
        Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                // Placeholder Emoji/Icon based on Stage
                val icon = when(stage) {
                    CreatureStage.EGG -> "🥚"
                    CreatureStage.BABY -> "🐣"
                    CreatureStage.CHILD -> "🐥"
                    CreatureStage.ADULT -> "🦅"
                    CreatureStage.MASTER -> "🐲"
                }
                Text(text = icon, style = MaterialTheme.typography.displayLarge)
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = stage.name, 
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Total: ${points.toInt()} pts",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

@Composable
fun GrassGrid(aggs: List<DailyAggEntity>) {
    val today = LocalDate.now()
    val startDate = today.minusDays(364) // Last 365 days

    // Create a map for quick lookup by date string (e.g. "YYYY-MM-DD")
    val aggsMap = aggs.associateBy { it.dateString }

    // Day of week ranges from 1 (Monday) to 7 (Sunday)
    // We want Sunday at the top (row 0), Monday at row 1, etc.
    val startDayOfWeek = if (startDate.dayOfWeek.value == 7) 0 else startDate.dayOfWeek.value

    val totalCells = startDayOfWeek + 365

    // A horizontal grid with 7 rows
    LazyHorizontalGrid(
        rows = GridCells.Fixed(7),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
        modifier = Modifier
            .fillMaxWidth()
            .height((20 * 7 + 4 * 6).dp) // Exactly height for 7 boxes + spacing
    ) {
        items(totalCells) { index ->
            if (index < startDayOfWeek) {
                // Invisible padding box so the dates align to the correct week day
                Box(modifier = Modifier.size(20.dp))
            } else {
                val dateOffset = index - startDayOfWeek
                val currentDate = startDate.plusDays(dateOffset.toLong())
                val dateStr = currentDate.format(DateTimeFormatter.ISO_LOCAL_DATE)

                val agg = aggsMap[dateStr]
                val points = agg?.pointsTotal ?: 0.0

                // Intensity scales from 0.3 to 1.0 based on points (assuming 100+ is max green)
                val intensity = if (points > 0) {
                    (0.3 + (points / 150.0) * 0.7).coerceIn(0.3, 1.0).toFloat()
                } else 0f

                Box(
                    modifier = Modifier
                        .size(20.dp)
                        .background(
                            color = if (points > 0) MaterialTheme.colorScheme.primary.copy(alpha = intensity)
                            else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.05f),
                            shape = RoundedCornerShape(4.dp)
                        )
                )
            }
        }
    }
}
