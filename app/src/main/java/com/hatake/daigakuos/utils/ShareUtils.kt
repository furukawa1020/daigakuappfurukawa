package com.hatake.daigakuos.utils

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import androidx.core.content.FileProvider
import com.hatake.daigakuos.data.local.entity.NodeEntity
import java.io.File
import java.io.FileOutputStream

object ShareUtils {

    fun createShareIntent(
        context: Context,
        completedNode: NodeEntity,
        pointsGained: Float,
        streak: Int,
        isOnCampus: Boolean,
        earnedMokoCoins: Int = 0,
        earnedStarCrystals: Int = 0,
        earnedCampusGems: Int = 0
    ): Intent {
        val locationTag = if (isOnCampus) "📍At University" else "🏠At Home"
        
        // Generate a 1080x1080 square image for social media
        val bitmap = Bitmap.createBitmap(1080, 1080, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        // Background color
        canvas.drawColor(Color.parseColor("#FFF5F6")) // Pale Pink
        
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#333333") // Dark gray
            textAlign = Paint.Align.CENTER
        }

        // Draw Title
        paint.textSize = 80f
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        canvas.drawText("🏆 ${completedNode.title} Completed!", 540f, 400f, paint)

        // Draw Points
        paint.textSize = 60f
        paint.color = Color.parseColor("#4F46E5") // Indigo
        canvas.drawText("+${pointsGained.toInt()} pts", 540f, 550f, paint)

        // Draw Stats (Location and Streak)
        paint.textSize = 45f
        paint.color = Color.parseColor("#666666")
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
        canvas.drawText("$locationTag  |  🔥Streak: $streak", 540f, 700f, paint)

        // Draw Rewards
        paint.textSize = 40f
        paint.color = Color.parseColor("#E65100") // Orange
        var rewardsText = ""
        if (earnedMokoCoins > 0) rewardsText += "🪙 +$earnedMokoCoins  "
        if (earnedStarCrystals > 0) rewardsText += "✨ +$earnedStarCrystals  "
        if (earnedCampusGems > 0) rewardsText += "💎 +$earnedCampusGems"
        if (rewardsText.isNotEmpty()) {
            canvas.drawText(rewardsText.trim(), 540f, 800f, paint)
        }

        // Draw App Branding
        paint.textSize = 40f
        paint.color = Color.parseColor("#B5EAD7") // Mint
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD_ITALIC)
        canvas.drawText("#DaigakuOS", 540f, 950f, paint)

        // Save Bitmap to the cache directory carefully exposed by FileProvider
        val imagesFolder = File(context.cacheDir, "images")
        imagesFolder.mkdirs()
        val file = File(imagesFolder, "share_achievement.png")
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }

        // Get URI using FileProvider defined in AndroidManifest.xml
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)

        // Define accompanying text
        val textItems = mutableListOf(
            "🏆 ${completedNode.title} Completed!",
            "+${pointsGained.toInt()} pts",
            "$locationTag | 🔥Streak: $streak"
        )
        if (earnedMokoCoins > 0) textItems.add("🪙 +$earnedMokoCoins MokoCoins")
        if (earnedStarCrystals > 0) textItems.add("✨ +$earnedStarCrystals StarCrystals")
        if (earnedCampusGems > 0) textItems.add("💎 +$earnedCampusGems CampusGems")
        textItems.add("\n#DaigakuOS")
        
        val text = textItems.joinToString("\n")

        // Create the ACTION_SEND intent with image and text
        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_TEXT, text)
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        
        return Intent.createChooser(sendIntent, "実績をシェア")
    }

    fun createWeeklyReportIntent(
        context: Context,
        weekPoints: Double,
        activeDays: Int,
        creatureName: String
    ): Intent {
        // Generate a 1080x1080 square image for the weekly report
        val bitmap = Bitmap.createBitmap(1080, 1080, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        // Background color
        canvas.drawColor(Color.parseColor("#E0F7FA")) // Soft Cyan
        
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#006064") // Dark Cyan
            textAlign = Paint.Align.CENTER
        }

        // Draw Title
        paint.textSize = 80f
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        canvas.drawText("📊 Weekly Report", 540f, 250f, paint)

        // Draw Points
        paint.textSize = 70f
        paint.color = Color.parseColor("#00838F")
        canvas.drawText("Total Points: ${weekPoints.toInt()} pts", 540f, 450f, paint)

        // Draw Active Days
        paint.textSize = 60f
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
        canvas.drawText("Active Days: $activeDays / 7", 540f, 600f, paint)

        // Draw Pet Status
        paint.textSize = 50f
        paint.color = Color.parseColor("#006064")
        canvas.drawText("Pet Evolution: $creatureName", 540f, 750f, paint)

        // Draw App Branding
        paint.textSize = 40f
        paint.color = Color.parseColor("#00ACC1")
        paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD_ITALIC)
        canvas.drawText("#DaigakuOS", 540f, 950f, paint)

        // Save Bitmap to the cache directory carefully exposed by FileProvider
        val imagesFolder = File(context.cacheDir, "images")
        imagesFolder.mkdirs()
        // Use a different filename
        val file = File(imagesFolder, "weekly_report.png")
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }

        // Get URI using FileProvider defined in AndroidManifest.xml
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)

        // Define accompanying text
        val text = """
            📊 This Week's Report!
            Total Points: ${weekPoints.toInt()} pts
            Active Days: $activeDays
            
            #DaigakuOS
        """.trimIndent()

        // Create the ACTION_SEND intent with image and text
        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_TEXT, text)
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        
        return Intent.createChooser(sendIntent, "ウィークリーレポートをシェア")
    }
}
