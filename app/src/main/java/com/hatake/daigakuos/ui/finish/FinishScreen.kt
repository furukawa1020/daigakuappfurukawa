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
import androidx.compose.ui.unit.dp
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
    
    Scaffold(
        floatingActionButton = {
            ExtendedFloatingActionButton(
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
                            onSuccess = onFinish
                        )
                    }
                },
                icon = { Icon(Icons.Default.Check, "Done") },
                text = { Text("成果を記録") }
            )
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
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(title, style = MaterialTheme.typography.bodyLarge)
            Text(type, style = MaterialTheme.typography.labelSmall)
        }
    }
}
