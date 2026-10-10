package com.example.c001apk.compose.ui.theme

import android.app.Activity
import android.os.Build.VERSION.SDK_INT
import android.os.Build.VERSION_CODES.Q
import androidx.annotation.FloatRange
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.Density
import androidx.core.graphics.ColorUtils
import androidx.core.view.WindowCompat
import com.example.c001apk.compose.ThemeType
import com.example.c001apk.compose.constant.Constants.seedColors
import top.yukonga.miuix.kmp.theme.ColorSchemeMode
import top.yukonga.miuix.kmp.theme.Colors
import top.yukonga.miuix.kmp.theme.MiuixTheme
import top.yukonga.miuix.kmp.theme.ThemeController
import top.yukonga.miuix.kmp.theme.ThemePaletteStyle
import androidx.compose.ui.unit.dp

@Composable
fun C001apkComposeTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    themeType: ThemeType = ThemeType.Default,
    seedColor: String? = null,
    materialYou: Boolean = true,
    pureBlack: Boolean = false,
    paletteStyle: Int = 0,
    fontScale: Float = 1.00f,
    contentScale: Float = 1.00f,
    content: @Composable () -> Unit
) {

    // MIUIX palette style aligns 1:1 with the app's stored PaletteStyle index.
    val style = ThemePaletteStyle.entries.getOrNull(paletteStyle) ?: ThemePaletteStyle.TonalSpot

    // Resolve a seed key color: explicit custom seed > theme-type seed > default blue.
    val seedLong = "FF$seedColor".toLongOrNull(16)
    val themeTypeSeed = seedColors.getOrNull(ThemeType.entries.indexOf(themeType))
    val keyColor: Color? = when {
        seedLong != null -> Color(seedLong)
        themeTypeSeed != null -> Color(themeTypeSeed.toLong())
        else -> null
    }

    val controller = rememberController(
        darkTheme = darkTheme,
        pureBlack = pureBlack,
        materialYou = materialYou,
        keyColor = keyColor,
        style = style,
    )

    val baseColors = controller.currentColors()
    val colors = if (pureBlack && darkTheme) baseColors.toAmoled() else baseColors

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            @Suppress("DEPRECATION")
            window.statusBarColor = Color.Transparent.toArgb()
            @Suppress("DEPRECATION")
            window.navigationBarColor = Color.Transparent.toArgb()
            if (SDK_INT >= Q) {
                @Suppress("DEPRECATION")
                window.isStatusBarContrastEnforced = false
                @Suppress("DEPRECATION")
                window.isNavigationBarContrastEnforced = false
            }
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
            WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars =
                !darkTheme
        }
    }

    MiuixTheme(
        colors = colors,
        content = {
            CompositionLocalProvider(
                LocalDensity provides Density(
                    LocalDensity.current.density * contentScale,
                    LocalDensity.current.fontScale * fontScale,
                )
            ) {
                content()
            }
        }
    )
}

@Composable
private fun rememberController(
    darkTheme: Boolean,
    pureBlack: Boolean,
    materialYou: Boolean,
    keyColor: Color?,
    style: ThemePaletteStyle,
): ThemeController {
    // pureBlack only affects the dark scheme (it is applied as an AMOLED overlay later).
    val schemeMode: ColorSchemeMode = when {
        darkTheme -> ColorSchemeMode.Dark
        else -> ColorSchemeMode.Light
    }
    return androidx.compose.runtime.remember(darkTheme, pureBlack, materialYou, keyColor, style) {
        when {
            // System Monet (Android 12+ dynamic color), no custom seed.
            materialYou && keyColor == null ->
                ThemeController(ColorSchemeMode.MonetSystem)

            // Custom seed color driven dynamic scheme (with light/dark).
            keyColor != null -> when (schemeMode) {
                ColorSchemeMode.Light ->
                    ThemeController(ColorSchemeMode.MonetLight, keyColor = keyColor, paletteStyle = style)

                else ->
                    ThemeController(ColorSchemeMode.MonetDark, keyColor = keyColor, paletteStyle = style)
            }

            // No custom color and Material You off: plain light/dark scheme.
            else -> when (schemeMode) {
                ColorSchemeMode.Light -> ThemeController(ColorSchemeMode.Light)
                else -> ThemeController(ColorSchemeMode.Dark)
            }
        }
    }
}

fun Color.darken(fraction: Float = 0.5f): Color =
    Color(toArgb().blend(Color.Black.toArgb(), fraction))

fun Int.blend(
    color: Int,
    @FloatRange(from = 0.0, to = 1.0) fraction: Float = 0.5f,
): Int = ColorUtils.blendARGB(this, color, fraction)

/**
 * Produce an AMOLED (pure black) variant of a Miuix [Colors] scheme.
 */
fun Colors.toAmoled(): Colors {
    return copy(
        primary = primary.darken(0.3f),
        onPrimary = onPrimary.darken(0.3f),
        primaryContainer = primaryContainer.darken(0.3f),
        onPrimaryContainer = onPrimaryContainer.darken(0.3f),
        secondary = secondary.darken(0.3f),
        onSecondary = onSecondary.darken(0.3f),
        secondaryContainer = secondaryContainer.darken(0.3f),
        onSecondaryContainer = onSecondaryContainer.darken(0.3f),
        tertiaryContainer = tertiaryContainer.darken(0.3f),
        onTertiaryContainer = onTertiaryContainer.darken(0.2f),
        background = Color.Black,
        onBackground = onBackground.darken(0.15f),
        surface = Color.Black,
        onSurface = onSurface.darken(0.15f),
        surfaceVariant = surfaceVariant,
        onSurfaceVariantSummary = onSurfaceVariantSummary,
        outline = outline.darken(0.2f),
        surfaceContainer = surfaceContainer.darken(),
        surfaceContainerHigh = surfaceContainerHigh.darken(),
        surfaceContainerHighest = surfaceContainerHighest.darken(0.4f),
    )
}

/**
 * Miuix has no Material3 `shapes` surface. These are the only corner shapes the
 * app used, exposed as [MiuixShapes] for a mechanical migration.
 */
object MiuixShapes {
    val medium = RoundedCornerShape(12.dp)
    val large = RoundedCornerShape(28.dp)
}
