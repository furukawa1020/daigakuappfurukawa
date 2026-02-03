package com.hatake.daigakuos.ui.tree

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.hatake.daigakuos.data.local.entity.NodeEntity
import com.hatake.daigakuos.data.local.entity.ProjectType

@Composable
fun TreeScreen(
    onBack: () -> Unit
) {
    // Dummy Data
    val projects = remember {
        listOf(
            "Project A: Statistics" to ProjectType.STUDY,
            "Project B: Android App" to ProjectType.MAKE
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Tree (Goal Management)") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Text("Back") // Use Icon in real app
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { /* Add Node Dialog */ }) {
                Icon(Icons.Default.Add, contentDescription = "Add")
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            projects.forEach { (name, type) ->
                item {
                    Text(
                        text = name,
                        style = MaterialTheme.typography.titleLarge,
                        modifier = Modifier.padding(vertical = 8.dp)
                    )
                }
                
                // Dummy Nodes for each project
                items(3) { index ->
                    NodeItem(
                        node = NodeEntity(
                            id = index.toLong(),
                            projectId = 0, // Mock
                            title = "Task ${index + 1} for $name",
                            type = type
                        )
                    )
                }
            }
            
            item {
                Spacer(modifier = Modifier.height(64.dp))
            }
        }
    }
}

@Composable
fun NodeItem(node: NodeEntity) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
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
                    text = "${node.estimateMinutes} min",
                    style = MaterialTheme.typography.labelSmall
                )
            }
            Icon(Icons.Default.ChevronRight, contentDescription = "Detail")
        }
    }
}
