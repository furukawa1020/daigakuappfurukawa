package com.hatake.daigakuos.ui.collection

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AchievementGalleryScreen(
    onBack: () -> Unit,
    viewModel: AchievementGalleryViewModel = hiltViewModel()
) {
    val achievements by viewModel.uiState.collectAsState()

    // Mark as viewed when we leave the screen or enter it
    DisposableEffect(Unit) {
        onDispose {
            viewModel.markAllAsViewed()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("実績・バッジ") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .padding(16.dp)
        ) {
            
            // Progress Header
            val unlockedCount = achievements.count { it.isUnlocked }
            val totalCount = achievements.size
            
            Surface(
                shape = RoundedCornerShape(24.dp),
                color = MaterialTheme.colorScheme.secondaryContainer,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "コレクション達成度",
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.8f)
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "$unlockedCount / $totalCount",
                        style = MaterialTheme.typography.displaySmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                contentPadding = PaddingValues(bottom = 24.dp)
            ) {
                items(achievements) { badge ->
                    AchievementBadgeCard(badge)
                }
            }
        }
    }
}

@Composable
fun AchievementBadgeCard(item: AchievementUiItem) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.fillMaxWidth()
    ) {
        Box(
            modifier = Modifier
                .size(80.dp)
                .clip(CircleShape)
                .background(
                    if (item.isUnlocked) MaterialTheme.colorScheme.primaryContainer 
                    else MaterialTheme.colorScheme.surfaceVariant
                ),
            contentAlignment = Alignment.Center
        ) {
            if (item.isUnlocked) {
                Text(text = item.emoji, fontSize = 40.sp)
                if (item.isNew) {
                    // "New" badge 
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .offset(x = (-4).dp, y = 4.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(Color.Red)
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = "NEW",
                            color = Color.White,
                            fontSize = 8.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            } else {
                Text(text = "🔒", fontSize = 24.sp, color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f))
            }
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = if (item.isUnlocked) item.title else "???",
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
            color = if (item.isUnlocked) MaterialTheme.colorScheme.onBackground else Color.Gray,
            maxLines = 2
        )
    }
}
