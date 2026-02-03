package com.hatake.daigakuos.ui.now

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun NowScreen(
    nodeId: String?,
    onComplete: () -> Unit,
    viewModel: NowViewModel = hiltViewModel()
) {
    // Start session on enter
    LaunchedEffect(nodeId) {
        viewModel.startSession(nodeId)
    }

    val nodeTitle = "集中セッション" // TODO: Fetch Node Title using UseCase if needed
    
    var timeElapsed by remember { mutableLongStateOf(0L) }
    var isRunning by remember { mutableStateOf(true) }
    var showDialog by remember { mutableStateOf(false) }
    
    // Timer Effect
    LaunchedEffect(isRunning) {
        if (isRunning) {
            val startTime = System.currentTimeMillis() - timeElapsed
            while (isRunning) {
                timeElapsed = System.currentTimeMillis() - startTime
                delay(1000L)
            }
        }
    }

    if (showDialog) {
        CompletionDialog(
            initialMinutes = (timeElapsed / 1000 / 60).toInt().coerceAtLeast(10),
            onDismiss = { showDialog = false },
            onConfirm = { minutes, focus ->
                showDialog = false
                viewModel.completeSession(minutes, focus, onComplete)
            }
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(text = "現在集中タスク", style = MaterialTheme.typography.labelLarge)
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = nodeTitle,
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.primary
        )
        
        Spacer(modifier = Modifier.height(48.dp))
        
        // Timer Display
        val minutes = (timeElapsed / 1000) / 60
        val seconds = (timeElapsed / 1000) % 60
        Text(
            text = "%02d:%02d".format(minutes, seconds),
            fontSize = 64.sp,
            style = MaterialTheme.typography.displayLarge
        )
        
        Spacer(modifier = Modifier.height(48.dp))
        
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            Button(
                onClick = { isRunning = !isRunning },
                colors = ButtonDefaults.buttonColors(containerColor = Color.Gray)
            ) {
                Text(if (isRunning) "一時停止" else "再開")
            }
            
            Button(
                onClick = { 
                    isRunning = false
                    showDialog = true
                }
            ) {
                Text("完了")
            }
        }
    }
}

@Composable
fun CompletionDialog(
    initialMinutes: Int,
    onDismiss: () -> Unit,
    onConfirm: (Int, Int) -> Unit
) {
    var selectedMinutes by remember { mutableIntStateOf(initialMinutes) }
    var selectedFocus by remember { mutableIntStateOf(3) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("セッション報告") },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text("自己申告時間 (分)", style = MaterialTheme.typography.labelMedium)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    listOf(10, 25, 50, 90).forEach { min ->
                        FilterChip(
                            selected = selectedMinutes == min,
                            onClick = { selectedMinutes = min },
                            label = { Text("$min") }
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Text("集中度 (1-5)", style = MaterialTheme.typography.labelMedium)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    (1..5).forEach { lvl ->
                        FilterChip(
                            selected = selectedFocus == lvl,
                            onClick = { selectedFocus = lvl },
                            label = { Text("$lvl") }
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(onClick = { onConfirm(selectedMinutes, selectedFocus) }) {
                Text("記録保存")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("キャンセル")
            }
        }
    )
}
