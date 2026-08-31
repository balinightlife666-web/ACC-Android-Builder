package com.ardacore.moshi

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val MoshiPurple = Color(0xFF7C5CFC)
private val MoshiPurpleSoft = Color(0xFFB9A7FF)
private val MoshiInk = Color(0xFF0B0B10)
private val MoshiSurface = Color(0xFF14141C)
private val MoshiSurface2 = Color(0xFF1D1D28)
private val MoshiText = Color(0xFFF7F5FF)
private val MoshiMuted = Color(0xFFB7B2C8)
private val MoshiGreen = Color(0xFF4CD7A5)

private val DarkColors = darkColorScheme(
    primary = MoshiPurpleSoft,
    onPrimary = Color(0xFF24164C),
    primaryContainer = Color(0xFF342467),
    onPrimaryContainer = Color(0xFFE9E2FF),
    secondary = MoshiGreen,
    onSecondary = Color(0xFF002118),
    background = MoshiInk,
    onBackground = MoshiText,
    surface = MoshiSurface,
    onSurface = MoshiText,
    surfaceVariant = MoshiSurface2,
    onSurfaceVariant = MoshiMuted,
    outline = Color(0xFF5D596A),
)

private val LightColors = lightColorScheme(
    primary = MoshiPurple,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFE8E0FF),
    onPrimaryContainer = Color(0xFF24164C),
    secondary = Color(0xFF006B53),
    background = Color(0xFFF9F7FF),
    onBackground = Color(0xFF1A1820),
    surface = Color.White,
    onSurface = Color(0xFF1A1820),
    surfaceVariant = Color(0xFFF0ECF7),
    onSurfaceVariant = Color(0xFF625D6B),
)

@Composable
fun MoshiTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        content = content,
    )
}
