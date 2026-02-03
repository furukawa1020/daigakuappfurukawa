package com.hatake.daigakuos.ui.home

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hatake.daigakuos.data.local.entity.NodeEntity

@Composable
fun HomeScreen(
    onNavigateToNow: (Long) -> Unit,
    onNavigateToTree: () -> Unit,
    onNavigateToStats: () -> Unit
) {
    // These would normally come from a ViewModel
    val currentPoints by remember { mutableFloatStateOf(1250f) } // Dummy Tank Level
    val isOnCampus by remember { mutableStateOf(true) } // Dummy State
    val recommendations = remember {
        listOf(
            // Dummy Data
            NodeEntity(id = 1, projectId = 1, title = "DataStruct Lec 5", type = com.hatake.daigakuos.data.local.entity.ProjectType.STUDY, estimateMinutes = 25),
            NodeEntity(id = 2, projectId = 2, title = "Read Vaswani 2017", type = com.hatake.daigakuos.data.local.entity.ProjectType.RESEARCH, estimateMinutes = 50)
        )
    }

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(onClick = onNavigateToTree) {
                Text("+")
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Header: Status Area
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = if (isOnCampus) "Location: CAMPUS (x1.5)" else "Location: HOME (x1.0)",
                    color = if (isOnCampus) MaterialTheme.colorScheme.primary else Color.Gray,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Lvl. 12",
                    fontSize = 18.sp
                )
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Center: The TANK
            // "貯まる" Visualization
            Box(
                modifier = Modifier
                    .size(240.dp)
                    .clickable { onNavigateToStats() }, // Tap tank to see stats/organism
                contentAlignment = Alignment.Center
            ) {
                // Placeholder Canvas for Liquid
                Canvas(modifier = Modifier.fillMaxSize()) {
                    drawCircle(
                        color = Color.LightGray.copy(alpha = 0.2f),
                        radius = size.minDimension / 2
                    )
                    // Draw liquid level (simplified)
                    val liquidHeight = size.height * 0.6f // 60% full
                    drawRect(
                        color = Color(0xFF42A5F5).copy(alpha = 0.8f),
                        topLeft = Offset(size.width * 0.2f, size.height - liquidHeight),
                        size = androidx.compose.ui.geometry.Size(size.width * 0.6f, liquidHeight)
                    )
                }
                Text(
                    text = "${currentPoints.toInt()} pts",
                    style = MaterialTheme.typography.headlineLarge,
                    fontWeight = FontWeight.ExtraBold
                )
            }

            Spacer(modifier = Modifier.weight(1f))

            // Bottom: Recommendations
            Text(
                text = "Next Action",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.align(Alignment.Start)
            )
            Spacer(modifier = Modifier.height(8.dp))

            recommendations.forEach { node ->
                RecommendationCard(node = node, onClick = { onNavigateToNow(node.id) })
                Spacer(modifier = Modifier.height(8.dp))
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // "Today is Impossible" Button (Recovery Mode)
            OutlinedButton(
                onClick = { /* Activate Recovery Mode */ },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("今日は無理 (Recovery Mode)")
            }
        }
    }
}

@Composable
fun RecommendationCard(node: NodeEntity, onClick: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        onClick = onClick,
        colors = CardDefaults.cardColors(
            containerColor = when(node.type) {
                com.hatake.daigakuos.data.local.entity.ProjectType.STUDY -> Color(0xFFE3F2FD) // Blueish
                com.hatake.daigakuos.data.local.entity.ProjectType.RESEARCH -> Color(0xFFF3E5F5) // Purpleish
                else -> Color.White
            }
        )
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = node.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "${node.estimateMinutes} min • ${node.type.name}",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }
            Text(
                text = "GO",
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}
