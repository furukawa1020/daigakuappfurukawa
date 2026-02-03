package com.hatake.daigakuos.ui.stats

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun StatsScreen(
    onBack: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("箱庭 & 生物") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Text("戻る")
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
            // 1. Organism Visualization (Placeholder)
            Card(
                modifier = Modifier
                    .size(200.dp)
                    .padding(8.dp)
            ) {
                Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                    Text("謎の生物\n(進化中...)")
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // 2. Grass (Contribution Graph)
            Text("活動記録", style = MaterialTheme.typography.titleMedium)
            
            // Placeholder for Grass Grid
            // In real app, use a Canvas or LazyVerticalGrid
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                repeat(7) {
                    Surface(
                        modifier = Modifier.size(20.dp),
                        color = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f),
                        shape = MaterialTheme.shapes.small
                    ) { }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // 3. Stats Breakdown
            Text(
                "合計ポイント: 1250", 
                style = MaterialTheme.typography.headlineSmall
            )
        }
    }
}
