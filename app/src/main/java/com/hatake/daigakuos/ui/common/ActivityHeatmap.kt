package com.hatake.daigakuos.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Composable
fun ActivityHeatmap(
    dailyMinutes: Map<String, Int>, // "YYYY-MM-DD" to minutes
    modifier: Modifier = Modifier
) {
    val daysToShow = 28
    val today = LocalDate.now()
    val dates = (0 until daysToShow).map { today.minusDays((daysToShow - 1 - it).toLong()) }
    val formatter = DateTimeFormatter.ISO_LOCAL_DATE

    Column(modifier = modifier) {
        Text(
            text = "Activity (Last 4 Weeks)",
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            color = Color.Gray
        )
        Spacer(modifier = Modifier.height(8.dp))

        // Create a 4x7 grid using Column and Row
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            dates.chunked(7).forEach { weekDates ->
                Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    weekDates.forEach { date ->
                        val dateStr = date.format(formatter)
                        val minutes = dailyMinutes[dateStr] ?: 0

                        val color = when {
                            minutes == 0 -> Color(0xFFEEEEEE) // Grey 200 equivalent
                            minutes < 30 -> Color(0xFFC8E6C9) // Light Green 100
                            minutes < 60 -> Color(0xFFA5D6A7) // Green 200
                            minutes < 120 -> Color(0xFF66BB6A) // Green 400
                            else -> Color(0xFF2E7D32) // Green 800
                        }

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .aspectRatio(1f)
                                .clip(RoundedCornerShape(4.dp))
                                .background(color)
                        )
                    }
                }
            }
        }
    }
}
