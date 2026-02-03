package com.hatake.daigakuos.ui.now

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

@Composable
fun NowScreen(
    nodeId: Long?,
    onComplete: () -> Unit
) {
    // In real app, fetch Node by ID
    val nodeTitle = "DataStruct Lec 5"
    
    var timeElapsed by remember { mutableLongStateOf(0L) }
    var isRunning by remember { mutableStateOf(true) }
    
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

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(text = "Now Focusing", style = MaterialTheme.typography.labelLarge)
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
                Text(if (isRunning) "Pause" else "Resume")
            }
            
            Button(
                onClick = { 
                    isRunning = false
                    // Show confirmation/feedback dialog here
                    onComplete() 
                }
            ) {
                Text("Complete")
            }
        }
    }
}
