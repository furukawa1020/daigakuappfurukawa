package com.hatake.daigakuos.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = Navy80,
    secondary = Gold80,
    tertiary = Slate80,
    background = Color(0xFF121212),
    surface = Color(0xFF1E1E1E)
)

private val LightColorScheme = lightColorScheme(
    primary = Navy40,
    secondary = Gold40,
    tertiary = Slate40,
    background = NeutralBg,
    surface = NeutralSurface
)

private val SakuraColorScheme = lightColorScheme(
    primary = Color(0xFFD81B60), // Deep Pink
    secondary = Color(0xFFF48FB1), // Light Pink
    tertiary = Color(0xFFFFC107), // Amber accent
    background = Color(0xFFFCE4EC), // Very Light Pink
    surface = Color(0xFFF8BBD0) // Pink Surface
)

private val OceanColorScheme = lightColorScheme(
    primary = Color(0xFF0277BD), // Deep Blue
    secondary = Color(0xFF4FC3F7), // Light Blue
    tertiary = Color(0xFF00E5FF), // Cyan accent
    background = Color(0xFFE1F5FE), // Very Light Blue
    surface = Color(0xFFB3E5FC) // Blue Surface
)

@Composable
fun DaigakuOSTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    themePreference: com.hatake.daigakuos.domain.repository.ThemePreference = com.hatake.daigakuos.domain.repository.ThemePreference.SYSTEM,
    // Disable dynamic color to enforce sophisticated branding
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when (themePreference) {
        com.hatake.daigakuos.domain.repository.ThemePreference.SAKURA -> SakuraColorScheme
        com.hatake.daigakuos.domain.repository.ThemePreference.OCEAN -> OceanColorScheme
        com.hatake.daigakuos.domain.repository.ThemePreference.DARK -> DarkColorScheme
        com.hatake.daigakuos.domain.repository.ThemePreference.LIGHT -> LightColorScheme
        else -> if (darkTheme) DarkColorScheme else LightColorScheme
    }
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
