package com.hatake.daigakuos.ui.tree

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.runtime.collectAsState
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.NodeType

@Composable
fun TreeScreen(
    onBack: () -> Unit,
    onNavigateToNow: (String) -> Unit, // Added
    viewModel: TreeViewModel = hiltViewModel()
) {
    val nodes by viewModel.nodes.collectAsState()
    var showDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("ツリー (目標管理)") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Text("戻る") // Use Icon in real app
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { showDialog = true }) {
                Icon(Icons.Default.Add, contentDescription = "Add")
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding)) {
             LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
            ) {
                // Group by Project (Simulated for MVP: Group by Type)
                val grouped = nodes.groupBy { it.type }
                
                if (nodes.isEmpty()) {
                    item {
                        Text("タスクがありません。「+」ボタンで追加してください。")
                    }
                }

                NodeType.values().forEach { enumType ->
                    val typeNodes = grouped[enumType.name] ?: emptyList()
                    
                    if (typeNodes.isNotEmpty()) {
                        val sectionName = when(enumType) {
                            NodeType.STUDY -> "学習"
                            NodeType.RESEARCH -> "研究"
                            NodeType.MAKE -> "制作"
                            NodeType.ADMIN -> "事務/運営"
                        }
                        item {
                             Text(
                                text = sectionName,
                                style = MaterialTheme.typography.titleLarge,
                                modifier = Modifier.padding(vertical = 8.dp)
                            )
                        }
                        items(typeNodes) { node ->
                            NodeItem(
                                node = node,
                                onClick = { onNavigateToNow(node.id) }
                            )
                        }
                    }
                }
                
                item {
                    Spacer(modifier = Modifier.height(64.dp))
                }
            }
        }
        
        if (showDialog) {
            AddNodeDialog(
                onDismiss = { showDialog = false },
                onConfirm = { title, minutes, type ->
                    viewModel.addNode(title, minutes, type)
                    showDialog = false
                }
            )
        }
    }
}

@Composable
fun AddNodeDialog(
    onDismiss: () -> Unit,
    onConfirm: (String, Int, NodeType) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var minutes by remember { mutableStateOf("30") }
    var selectedType by remember { mutableStateOf(NodeType.STUDY) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("タスク追加") },
        text = {
            Column {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("タイトル") }
                )
                OutlinedTextField(
                    value = minutes,
                    onValueChange = { minutes = it },
                    label = { Text("見積もり時間 (分)") }
                )
                // Simple Type Selector
                Row {
                    NodeType.values().forEach { type ->
                        val label = when(type) {
                            NodeType.STUDY -> "学習"
                            NodeType.RESEARCH -> "研究"
                            NodeType.MAKE -> "制作"
                            NodeType.ADMIN -> "事務"
                        }
                        TextButton(
                            onClick = { selectedType = type },
                            colors = ButtonDefaults.textButtonColors(
                                contentColor = if(selectedType == type) MaterialTheme.colorScheme.primary else androidx.compose.ui.graphics.Color.Gray
                            )
                        ) {
                            Text(label)
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(onClick = {
                if (title.isNotBlank()) {
                    onConfirm(title, minutes.toIntOrNull() ?: 25, selectedType)
                }
            }) {
                Text("追加")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("キャンセル")
            }
        }
    )
}

@Composable
fun NodeItem(node: NodeEntity, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        onClick = onClick,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .padding(12.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(text = node.title, style = MaterialTheme.typography.bodyLarge)
                Text(
                    text = "${node.estimateMin} 分",
                    style = MaterialTheme.typography.labelSmall
                )
            }
            Icon(Icons.Default.ArrowForward, contentDescription = "Detail")
        }
    }
}
