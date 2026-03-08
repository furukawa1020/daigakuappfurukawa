package com.hatake.daigakuos.ui.finish

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.hatake.daigakuos.data.local.entity.NodeType

@Composable
fun FinishScreen(
    sessionId: String,
    elapsedMinutes: Int,
    onFinish: () -> Unit,
    viewModel: FinishViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    var selectedNodeId by remember { mutableStateOf<String?>(null) }
    var newTaskTitle by remember { mutableStateOf("") }
    var newTaskType by remember { mutableStateOf(NodeType.STUDY) }
    
    var finalMinutes by remember { mutableIntStateOf(elapsedMinutes) }
    var finalFocus by remember { mutableIntStateOf(3) }
    
    val context = androidx.compose.ui.platform.LocalContext.current

    Scaffold(
        bottomBar = {
            Surface(
                color = MaterialTheme.colorScheme.surface,
                tonalElevation = 16.dp, // Higher elevation for the bottom bar
                shape = androidx.compose.foundation.shape.RoundedCornerShape(topStart = 32.dp, topEnd = 32.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 20.dp),
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
                            }
                        },
                        modifier = Modifier.weight(1f).height(56.dp),
                        shape = androidx.compose.foundation.shape.CircleShape
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
                        shape = androidx.compose.foundation.shape.CircleShape
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
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Section 1: Result
            item {
                Text("セッション終了", style = MaterialTheme.typography.headlineSmall)
                Spacer(modifier = Modifier.height(8.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("$finalMinutes 分", style = MaterialTheme.typography.displayMedium)
                    Spacer(modifier = Modifier.width(16.dp))
                    IconButton(onClick = { if(finalMinutes > 5) finalMinutes -= 5 }) { Text("-") }
                    IconButton(onClick = { finalMinutes += 5 }) { Text("+") }
                }
            }
            
            // Section 2: Attribution
            item {
                Text("何をやりましたか？", style = MaterialTheme.typography.titleMedium)
                
                OutlinedTextField(
                    value = newTaskTitle,
                    onValueChange = { 
                        newTaskTitle = it 
                        selectedNodeId = null 
                    },
                    label = { Text("新しい成果 (1行入力)") },
                    modifier = Modifier.fillMaxWidth()
                )
                
                if (newTaskTitle.isNotBlank() && selectedNodeId == null) {
                    TypeSelector(selected = newTaskType, onSelect = { newTaskType = it })
                }
            }
            
            // Suggestions
            item {
                Text("履歴・候補から選択", style = MaterialTheme.typography.labelLarge)
            }
            
            items(uiState.suggestions) { node ->
                SuggestionItem(
                    title = node.title,
                    type = node.type,
                    isSelected = selectedNodeId == node.id,
                    onClick = {
                        selectedNodeId = node.id
                        newTaskTitle = "" 
                    }
                )
            }
            
            item {
                 Text("集中度: $finalFocus", style = MaterialTheme.typography.titleMedium)
                 Slider(
                    value = finalFocus.toFloat(),
                    onValueChange = { finalFocus = it.toInt() },
                    valueRange = 1f..5f,
                    steps = 3
                 )
            }
            
            item { Spacer(modifier = Modifier.height(80.dp)) }
        }
    }
}

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

@Composable
fun SuggestionItem(title: String, type: String, isSelected: Boolean, onClick: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable { onClick() },
        shape = androidx.compose.foundation.shape.RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Text(title, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(4.dp))
            Text(type, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.secondary)
        }
    }
}
