package com.hatake.daigakuos.ui.now

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.compose.runtime.collectAsState

@Composable
fun NowScreen(
    nodeId: String?,
    targetMinutes: Int? = null,
    taskTitle: String? = null,
    onComplete: (String, Int) -> Unit, // sessionId, minutes
    viewModel: NowViewModel = hiltViewModel()
) {
    // Start session on enter, but offset by charge-up duration (approx 3s)
    var showChargeUp by remember { mutableStateOf(true) }
    
    LaunchedEffect(nodeId, showChargeUp) {
        if (!showChargeUp) {
            viewModel.startSession(nodeId)
        }
    }

    val uiState by viewModel.uiState.collectAsState()
    val nodeTitle = taskTitle ?: uiState.nodeTitle
    val sessionStartTime = uiState.sessionStartTime
    
    var timeElapsed by remember { mutableLongStateOf(0L) }
    var isRunning by remember { mutableStateOf(true) }
    var showDialog by remember { mutableStateOf(false) }
    
    var showTargetReachedDialog by remember { mutableStateOf(false) }
    var targetReachedTriggered by remember { mutableStateOf(false) }
    var currentTargetMinutes by remember { mutableStateOf(targetMinutes) }

    // Timer Effect - calculate from session start time once available
    LaunchedEffect(isRunning, sessionStartTime) {
        if (isRunning && sessionStartTime != null) {
            while (isRunning) {
                timeElapsed = System.currentTimeMillis() - sessionStartTime
                
                // Check if target is reached
                if (currentTargetMinutes != null && !targetReachedTriggered && timeElapsed >= currentTargetMinutes!! * 60 * 1000L) {
                    isRunning = false
                    targetReachedTriggered = true
                    showTargetReachedDialog = true
                }
                
                delay(100L) // Update faster for smooth UI
            }
        }
    }

    // Colors
    val primaryColor = MaterialTheme.colorScheme.primary
    val secondaryColor = MaterialTheme.colorScheme.secondary
    val backgroundColor = MaterialTheme.colorScheme.background
    
    val hapticFeedback = androidx.compose.ui.platform.LocalHapticFeedback.current

    if (showChargeUp) {
        var chargeProgress by remember { mutableFloatStateOf(0f) }
        
        LaunchedEffect(Unit) {
            val duration = 3000L
            val step = 50L
            for (i in 0..(duration / step)) {
                delay(step)
                chargeProgress = i.toFloat() / (duration / step)
                if (i % 10 == 0L) {
                    hapticFeedback.performHapticFeedback(androidx.compose.ui.hapticfeedback.HapticFeedbackType.TextHandleMove)
                }
            }
            hapticFeedback.performHapticFeedback(androidx.compose.ui.hapticfeedback.HapticFeedbackType.LongPress)
            delay(200)
            showChargeUp = false
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(backgroundColor)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "深呼吸して...",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(48.dp))
            Box(modifier = Modifier.size(240.dp), contentAlignment = Alignment.Center) {
                Canvas(modifier = Modifier.fillMaxSize()) {
                    val strokeWidth = 16.dp.toPx()
                    drawCircle(
                        color = Color.LightGray.copy(alpha = 0.2f),
                        style = Stroke(width = strokeWidth)
                    )
                    drawArc(
                        brush = Brush.verticalGradient(listOf(primaryColor, secondaryColor)),
                        startAngle = -90f,
                        sweepAngle = chargeProgress * 360f,
                        useCenter = false,
                        style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                    )
                }
                Text(
                    text = "${(3 - (chargeProgress * 3)).toInt() + 1}",
                    style = MaterialTheme.typography.displayLarge,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    } else {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(backgroundColor)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween // Top/Center/Bottom
        ) {
        // Header
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "FOCUS SESSION",
                style = MaterialTheme.typography.labelMedium,
                letterSpacing = 2.sp,
                color = MaterialTheme.colorScheme.outline
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = nodeTitle,
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold
            )
        }
        
        // Center Timer
        Box(
            modifier = Modifier.size(300.dp),
            contentAlignment = Alignment.Center
        ) {
            val minutes = (timeElapsed / 1000) / 60
            val seconds = (timeElapsed / 1000) % 60
            
            // Animated Pulse Background
            val infiniteTransition = rememberInfiniteTransition()
            val pulseScale by infiniteTransition.animateFloat(
                initialValue = 0.8f,
                targetValue = 1.0f,
                animationSpec = infiniteRepeatable(
                    animation = tween(2000),
                    repeatMode = RepeatMode.Reverse
                )
            )
            
            if (isRunning) {
                Box(
                    modifier = Modifier
                        .size(300.dp * pulseScale)
                        .clip(CircleShape)
                        .background(primaryColor.copy(alpha = 0.05f))
                )
            }

            // Progress Ring
            Canvas(modifier = Modifier.fillMaxSize()) {
                val strokeWidth = 12.dp.toPx()
                // Track
                drawCircle(
                    color = Color.LightGray.copy(alpha = 0.2f),
                    style = Stroke(width = strokeWidth)
                )
                // Progress (Indeterminate look or just rotating? Let's do a fill based on 90m cap)
                // Cap at 90 mins for full circle
                val progress = (timeElapsed / 1000f) / (90 * 60f)
                val sweepAngle = (progress * 360f).coerceAtMost(360f)
                
                drawArc(
                    brush = Brush.verticalGradient(
                        colors = listOf(primaryColor, secondaryColor)
                    ),
                    startAngle = -90f,
                    sweepAngle = sweepAngle,
                    useCenter = false,
                    style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                )
            }
            
            // Text Time
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "%02d".format(minutes),
                    style = MaterialTheme.typography.displayLarge,
                    fontSize = 80.sp,
                    fontWeight = FontWeight.Thin,
                    color = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = "%02d".format(seconds),
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.secondary
                )
            }
        }
        
        // Controls
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Pause/Resume (Large FAB)
            FloatingActionButton(
                onClick = { isRunning = !isRunning },
                containerColor = if (isRunning) MaterialTheme.colorScheme.surfaceVariant else MaterialTheme.colorScheme.primary,
                contentColor = if (isRunning) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onPrimary,
                modifier = Modifier.size(72.dp)
            ) {
                Icon(
                    imageVector = if (isRunning) Icons.Default.Close else Icons.Default.PlayArrow,
                    contentDescription = "Toggle"
                )
            }
            
            Spacer(modifier = Modifier.width(32.dp))
            
            // Finish (Outlined)
            OutlinedButton(
                onClick = { 
                    isRunning = false
                    val minutes = (timeElapsed / 1000 / 60).toInt().coerceAtLeast(1)
                    val sessionId = viewModel.currentSessionId ?: ""
                    onComplete(sessionId, minutes)
                },
                modifier = Modifier.height(72.dp),
                shape = CircleShape,
                border = androidx.compose.foundation.BorderStroke(2.dp, MaterialTheme.colorScheme.primary)
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Default.Check, contentDescription = null)
                    Text("完了", style = MaterialTheme.typography.labelSmall)
                }
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        if (showTargetReachedDialog) {
            FiveMinuteReachedDialog(
                onDismiss = { showTargetReachedDialog = false },
                onExtend = {
                    currentTargetMinutes = (currentTargetMinutes ?: 0) + 5
                    targetReachedTriggered = false
                    showTargetReachedDialog = false
                    isRunning = true
                },
                onUnlimited = {
                    currentTargetMinutes = null
                    showTargetReachedDialog = false
                    isRunning = true
                },
                onFinish = {
                    showTargetReachedDialog = false
                    val minutes = (timeElapsed / 1000 / 60).toInt().coerceAtLeast(1)
                    val sessionId = viewModel.currentSessionId ?: ""
                    onComplete(sessionId, minutes)
                }
            )
        }
    }
    }
}

@Composable
fun FiveMinuteReachedDialog(
    onDismiss: () -> Unit,
    onExtend: () -> Unit,
    onUnlimited: () -> Unit,
    onFinish: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("目標時間達成！🎉") },
        text = { Text("お疲れ様です！目標時間に到達しました。\nこの後どうしますか？") },
        confirmButton = {
            Button(onClick = onFinish) {
                Text("終わり！")
            }
        },
        dismissButton = {
            Column(horizontalAlignment = Alignment.End) {
                TextButton(onClick = onExtend) {
                    Text("延長 (+5分)")
                }
                TextButton(onClick = onUnlimited) {
                    Text("ゾーンに入る (無制限)")
                }
            }
        }
    )
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
                Text("実績時間", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.secondary)
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    listOf(10, 25, 50, 90).forEach { min ->
                        FilterChip(
                            selected = selectedMinutes == min,
                            onClick = { selectedMinutes = min },
                            label = { Text("$min") },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = MaterialTheme.colorScheme.secondaryContainer
                            )
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(24.dp))
                
                Text("集中度", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.secondary)
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    (1..5).forEach { lvl ->
                        FilterChip(
                            selected = selectedFocus == lvl,
                            onClick = { selectedFocus = lvl },
                            label = { Text("$lvl") },
                             colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = MaterialTheme.colorScheme.primaryContainer
                            )
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onConfirm(selectedMinutes, selectedFocus) },
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
            ) {
                Text("記録する")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("キャンセル")
            }
        }
    )
}
