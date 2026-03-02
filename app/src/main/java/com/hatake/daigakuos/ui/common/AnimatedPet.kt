package com.hatake.daigakuos.ui.common

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun AnimatedPet(
    emoji: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 72.sp,
    showAura: Boolean = true
) {
    val transition = rememberInfiniteTransition(label = "PetAnimation")
    
    val scale by transition.animateFloat(
        initialValue = 1f,
        targetValue = 1.15f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "PetScale"
    )

    val offsetY by transition.animateFloat(
        initialValue = 0f,
        targetValue = -12f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "PetBounce"
    )

    val auraScale by transition.animateFloat(
        initialValue = 0.8f,
        targetValue = 1.4f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "AuraScale"
    )
    
    val auraAlpha by transition.animateFloat(
        initialValue = 0.1f,
        targetValue = 0.5f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "AuraAlpha"
    )

    Box(
        modifier = modifier
            .offset(y = offsetY.dp)
            .graphicsLayer(scaleX = scale, scaleY = scale),
        contentAlignment = Alignment.Center
    ) {
        if (showAura) {
            Canvas(modifier = Modifier.size((fontSize.value * 2.0).dp)) {
                drawCircle(
                    brush = Brush.radialGradient(
                        colors = listOf(
                            Color(0xFF00E5FF).copy(alpha = auraAlpha),    // Cyan core
                            Color(0xFFFF00FF).copy(alpha = auraAlpha * 0.4f), // Magenta mid
                            Color.Transparent                             // Fade out
                        )
                    ),
                    radius = size.minDimension / 2 * auraScale
                )
            }
        }
        
        Text(
            text = emoji,
            fontSize = fontSize
        )
    }
}
