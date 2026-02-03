package com.hatake.daigakuos.utils

import android.content.Context
import android.content.Intent
import com.hatake.daigakuos.data.local.entity.NodeEntity

object ShareUtils {

    fun createShareIntent(
        context: Context,
        completedNode: NodeEntity,
        pointsGained: Float,
        streak: Int,
        isOnCampus: Boolean
    ): Intent {
        val locationTag = if (isOnCampus) "📍At University" else "🏠At Home"
        
        // MVP: Share Text (Image generation would require View capture or Bitmap drawing which is complex for a util file)
        // Text format:
        // 🏆 [Task Name] Completed!
        // +150 pts (Lvl. 12)
        // 📍At University | 🔥Streak: 5
        // #DaigakuOS
        
        val text = """
            🏆 ${completedNode.title} Completed!
            +${pointsGained.toInt()} pts
            $locationTag | 🔥Streak: $streak
            
            #DaigakuOS
        """.trimIndent()

        val sendIntent: Intent = Intent().apply {
            action = Intent.ACTION_SEND
            putExtra(Intent.EXTRA_TEXT, text)
            type = "text/plain"
        }
        
        return Intent.createChooser(sendIntent, "Share Achievement")
    }
}
