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

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow

@Composable
fun HomeScreen(
    uiState: com.hatake.daigakuos.ui.home.HomeUiState,
    onNavigateToNow: (Long) -> Unit,
    onNavigateToTree: () -> Unit,
    onNavigateToStats: () -> Unit,
    onModeChange: (com.hatake.daigakuos.data.local.entity.Mode) -> Unit
) {
    val currentPoints = uiState.currentPoints
    val isOnCampus = uiState.isOnCampus
    val recommendations = uiState.recommendations

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick = onNavigateToTree,
                containerColor = MaterialTheme.colorScheme.secondary,
                contentColor = MaterialTheme.colorScheme.onSecondary
            ) {
                Text("+", fontSize = 24.sp)
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp), // Increased padding
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Header: Status Area
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Location Badge
                Surface(
                    shape = RoundedCornerShape(50),
                    color = if (isOnCampus) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
                    tonalElevation = 2.dp
                ) {
                    Text(
                        text = if (isOnCampus) "📍 UNIVERSITY (x1.5)" else "🏠 HOME (x1.0)",
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                        color = if (isOnCampus) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(48.dp))

            // Center: The TANK (Minimalist Circle)
            Box(
                modifier = Modifier
                    .size(260.dp)
                    .clickable { onNavigateToStats() },
                contentAlignment = Alignment.Center
            ) {
                Canvas(modifier = Modifier.fillMaxSize()) {
                    // Outer Ring
                    drawCircle(
                        color = Color.LightGray.copy(alpha = 0.2f),
                        style = androidx.compose.ui.graphics.drawscope.Stroke(width = 4.dp.toPx())
                    )
                    // Inner Progress (Simulated)
                    drawCircle(
                        color = Color(0xFF1A237E), // Navy logic color
                        radius = size.minDimension / 2 * 0.8f,
                        alpha = 0.1f
                    )
                }
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "${currentPoints.toInt()}",
                        style = MaterialTheme.typography.displayLarge,
                        fontWeight = FontWeight.Light, // Sophisticated Thin Font
                        color = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "POINTS",
                        style = MaterialTheme.typography.labelMedium,
                        letterSpacing = 2.sp,
                        color = MaterialTheme.colorScheme.secondary
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Bottom: Recommendations
            Text(
                text = "NEXT ACTION",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.outline,
                modifier = Modifier.align(Alignment.Start),
                letterSpacing = 1.5.sp
            )
            Spacer(modifier = Modifier.height(12.dp))

            if (recommendations.isEmpty()) {
                Text(
                    text = "No tasks available. Add one +",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.Gray,
                    modifier = Modifier.align(Alignment.Start)
                )
            }

            recommendations.forEach { node ->
                RecommendationCard(node = node, onClick = { onNavigateToNow(node.id) })
                Spacer(modifier = Modifier.height(12.dp))
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Recovery Mode (Minimalist Text Button)
            TextButton(
                onClick = { /* Activate Recovery Mode */ },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("REST MODE", color = MaterialTheme.colorScheme.tertiary)
            }
        }
    }
}

@Composable
fun RecommendationCard(node: NodeEntity, onClick: () -> Unit) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        onClick = onClick,
        colors = CardDefaults.elevatedCardColors(
            containerColor = MaterialTheme.colorScheme.surface,
        ),
        elevation = CardDefaults.elevatedCardElevation(defaultElevation = 4.dp)
    ) {
        Row(
            modifier = Modifier.padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = node.type.name.uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.secondary,
                    letterSpacing = 1.sp
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = node.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = "${node.estimateMinutes} MIN",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.Gray
                )
            }
            Icon(
                imageVector = Icons.Filled.PlayArrow,
                contentDescription = "Start",
                tint = MaterialTheme.colorScheme.primary
            )
        }
    }
}
