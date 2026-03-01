package com.hatake.daigakuos.ui.common

import androidx.compose.animation.core.*
import androidx.compose.foundation.layout.offset
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun AnimatedPet(
    emoji: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 72.sp
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

    Text(
        text = emoji,
        fontSize = fontSize,
        modifier = modifier
            .offset(y = offsetY.dp)
            .graphicsLayer(
                scaleX = scale,
                scaleY = scale
            )
    )
}
