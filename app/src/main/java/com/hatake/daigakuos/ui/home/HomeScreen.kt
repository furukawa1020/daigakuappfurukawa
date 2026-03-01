




package com.hatake.daigakuos.ui.home

import androidx.compose.animation.core.*
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
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hatake.daigakuos.data.local.entity.NodeEntity

import androidx.compose.material.icons.Icons
import com.hatake.daigakuos.ui.common.TutorialDialog
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Settings

import androidx.compose.material.icons.filled.Face

@Composable
fun HomeScreen(
    uiState: com.hatake.daigakuos.ui.home.HomeUiState,
    onNavigateToNow: (String) -> Unit,
    onNavigateToTree: () -> Unit,
    onNavigateToStats: () -> Unit,
    onNavigateToSettings: () -> Unit,
    onNavigateToCollection: () -> Unit,
    onModeChange: (com.hatake.daigakuos.data.local.entity.Mode) -> Unit
) {
    val currentPoints = uiState.currentPoints
    val isOnCampus = uiState.isOnCampus
    val recommendations = uiState.recommendations
    var showTutorial by remember { mutableStateOf(false) }

    if (showTutorial) {
        TutorialDialog(onDismiss = { showTutorial = false })
    }

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
                .padding(24.dp), 
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
                        text = if (isOnCampus) "📍 大学 (x1.5)" else "🏠 自宅 (x1.0)",
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                        color = if (isOnCampus) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }
                
                // Actions: Help & Settings
                Row {
                    IconButton(onClick = onNavigateToCollection) {
                        Icon(
                            imageVector = Icons.Filled.Face,
                            contentDescription = "Collection",
                            tint = MaterialTheme.colorScheme.onBackground
                        )
                    }
                    IconButton(onClick = { showTutorial = true }) {
                        Icon(
                            imageVector = Icons.Filled.Info,
                            contentDescription = "Help",
                            tint = MaterialTheme.colorScheme.onBackground
                        )
                    }
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(
                            imageVector = Icons.Filled.Settings,
                            contentDescription = "Settings",
                            tint = MaterialTheme.colorScheme.onBackground
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Currency Bar
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                CurrencyBadge("💰", uiState.mokoCoins)
                CurrencyBadge("✨", uiState.starCrystals)
                CurrencyBadge("💎", uiState.campusGems)
            }

            Spacer(modifier = Modifier.height(24.dp))
            
            // "Do Now" Button (Zero Input Start)
            Button(
                onClick = { onNavigateToNow("null") },
                modifier = Modifier.height(56.dp).fillMaxWidth(0.6f),
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary)
            ) {
                Icon(Icons.Default.PlayArrow, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("今やる (未定)", fontSize = 18.sp)
            }



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
                    AnimatedPetPlaceholder(level = uiState.organismState?.level ?: 1)
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Lv.${uiState.organismState?.level ?: 1} Moko",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "${currentPoints.toInt()} XP",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Light,
                        color = MaterialTheme.colorScheme.secondary
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Bottom: Recommendations
            Text(
                text = "次のアクション",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.outline,
                modifier = Modifier.align(Alignment.Start),
                letterSpacing = 1.5.sp
            )
            Spacer(modifier = Modifier.height(12.dp))

            if (recommendations.isEmpty()) {
                Text(
                    text = "タスクがありません。+ボタンで追加してください",
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
                onClick = { onModeChange(com.hatake.daigakuos.data.local.entity.Mode.RECOVERY) },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("回復モード", color = MaterialTheme.colorScheme.tertiary)
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
                val typeName = try {
                    when(com.hatake.daigakuos.data.local.entity.NodeType.valueOf(node.type)) {
                        com.hatake.daigakuos.data.local.entity.NodeType.STUDY -> "学習"
                        com.hatake.daigakuos.data.local.entity.NodeType.RESEARCH -> "研究"
                        com.hatake.daigakuos.data.local.entity.NodeType.MAKE -> "制作"
                        com.hatake.daigakuos.data.local.entity.NodeType.ADMIN -> "事務/運営"
                    }
                } catch (e: Exception) {
                    node.type // Fallback to raw string
                }
                Text(
                    text = typeName,
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
                    text = "${node.estimateMin ?: 25} 分",
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

@Composable
fun CurrencyBadge(emoji: String, amount: Int) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(text = emoji, fontSize = 16.sp)
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = "$amount",
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

import com.hatake.daigakuos.ui.common.AnimatedPet

@Composable
fun AnimatedPetPlaceholder(level: Int) {
    // We already moved AnimatedPet to common, 
    // so we can just use it here by passing in the emoji
    val petEmoji = when(level) {
        1 -> "🥚"
        in 2..3 -> "🐣"
        in 4..5 -> "🐥"
        in 6..10 -> "🐔"
        in 11..20 -> "🐲"
        else -> "🐉"
    }

    AnimatedPet(emoji = petEmoji)
}
