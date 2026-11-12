package com.example.c001apk.compose.ui.theme.glass

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Indication
import androidx.compose.foundation.LocalIndication
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.isSpecified
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.example.c001apk.compose.ui.theme.MiuixShapes
import dev.chrisbanes.haze.HazeInput
import dev.chrisbanes.haze.HazeState
import dev.chrisbanes.haze.glass.GlassStyle
import dev.chrisbanes.haze.glass.hazeGlass
import dev.chrisbanes.haze.hazeSource
import top.yukonga.miuix.kmp.basic.CardColors
import top.yukonga.miuix.kmp.basic.CardDefaults
import top.yukonga.miuix.kmp.basic.SurfaceDefaults
import top.yukonga.miuix.kmp.theme.LocalContentColor
import top.yukonga.miuix.kmp.theme.MiuixTheme
import top.yukonga.miuix.kmp.utils.PressFeedbackType

/**
 * 全局 Haze 状态：单 Activity 应用共享一个 state，根层 hazeSource 背景层与所有
 * hazeGlass 面板都挂在它上面。用全局单例而非 CompositionLocal，是为了让
 * [glassBackground] 能作为普通 Modifier 扩展用于非 @Composable 的 Modifier 链。
 */
object GlassEnv {
    val hazeState: HazeState = HazeState()
}

/**
 * 主题根层包装器：铺一层承载主题底色的 hazeSource 背景层，content 作为兄弟节点
 * 绘制在上层——玻璃采样背景层，不会递归捕获自身内容。保持纯色背景（用户要求）。
 */
@Composable
fun ProvideGlass(content: @Composable () -> Unit) {
    val backgroundColor = MiuixTheme.colorScheme.background
    Box(Modifier.fillMaxSize()) {
        Box(
            Modifier
                .fillMaxSize()
                .background(backgroundColor)
                .hazeSource(GlassEnv.hazeState)
        )
        content()
    }
}

private fun Shape.toRounded(): RoundedCornerShape = when (this) {
    RectangleShape -> RoundedCornerShape(0.dp)
    is RoundedCornerShape -> this
    else -> RoundedCornerShape(12.dp)
}

private fun glassStyle(roundedShape: RoundedCornerShape, bgColor: Color): GlassStyle =
    GlassStyle.regular.then {
        shape(roundedShape)
        backgroundColor(bgColor)
        tint(Color.White.copy(alpha = 0.06f))
        specularIntensity(0.6f)
    }

/** 信息流卡片共用的玻璃样式；无状态依赖，单例避免每次重组新建。 */
private val CardGlassStyle: GlassStyle = GlassStyle.regular.then {
    shape(RoundedCornerShape(12.dp))
    tint(Color.White.copy(alpha = 0.05f))
}

/** 玻璃容器公共实现：裁剪 + hazeGlass + 透传 MIUIX 的 LocalContentColor。 */
@Composable
private fun GlassBox(
    modifier: Modifier,
    shape: Shape,
    backgroundColor: Color,
    contentColor: Color,
    content: @Composable () -> Unit,
) {
    val style = remember(shape, backgroundColor) {
        glassStyle(shape.toRounded(), backgroundColor)
    }
    CompositionLocalProvider(LocalContentColor provides contentColor) {
        Box(
            modifier
                .clip(shape)
                .hazeGlass(input = HazeInput.Sources(GlassEnv.hazeState), style = style),
            propagateMinConstraints = true,
        ) {
            content()
        }
    }
}

/**
 * 液态玻璃 Card：签名合并自 MIUIX Card 的两个重载（参数全部有默认值），
 * 调用点只需把 import 从 `top.yukonga.miuix.kmp.basic.Card` 切到本文件即可。
 */
@Composable
fun Card(
    modifier: Modifier = Modifier,
    cornerRadius: Dp = CardDefaults.CornerRadius,
    insideMargin: PaddingValues = CardDefaults.InsideMargin,
    colors: CardColors = CardDefaults.defaultColors(),
    pressFeedbackType: PressFeedbackType = PressFeedbackType.None,
    showIndication: Boolean = false,
    holdDownState: Boolean = false,
    onClick: (() -> Unit)? = null,
    onLongPress: (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    val currentOnClick by rememberUpdatedState(onClick)
    val currentOnLongPress by rememberUpdatedState(onLongPress)
    val interactionSource = remember { MutableInteractionSource() }
    val indication = if (showIndication) LocalIndication.current else null
    val clickModifier = if (onClick != null || onLongPress != null) {
        Modifier.combinedClickable(
            interactionSource = interactionSource,
            indication = indication,
            onClick = { currentOnClick?.invoke() },
            onLongClick = if (onLongPress != null) {
                { currentOnLongPress?.invoke() }
            } else null,
        )
    } else Modifier
    GlassBox(
        modifier = modifier,
        shape = RoundedCornerShape(cornerRadius),
        backgroundColor = colors.color.copy(alpha = 0.65f),
        contentColor = colors.contentColor,
    ) {
        Column(
            Modifier
                .then(clickModifier)
                .padding(insideMargin),
            content = content,
        )
    }
}

/**
 * 液态玻璃 Surface：签名合并自 MIUIX Surface 的两个重载。
 * 仅用于卡片式 Surface；全屏根容器请继续用 MIUIX 原生 Surface。
 */
@Composable
fun Surface(
    onClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    shape: Shape = SurfaceDefaults.Shape,
    color: Color = Color.Unspecified,
    contentColor: Color = Color.Unspecified,
    border: BorderStroke? = null,
    shadowElevation: Dp = SurfaceDefaults.ShadowElevation,
    interactionSource: MutableInteractionSource? = null,
    indication: Indication? = null,
    content: @Composable () -> Unit,
) {
    val resolvedColor = if (color.isSpecified) color else MiuixTheme.colorScheme.surface
    val resolvedContentColor =
        if (contentColor.isSpecified) contentColor else MiuixTheme.colorScheme.onSurface
    val clickModifier = if (onClick != null) {
        Modifier.clickable(
            interactionSource = interactionSource,
            indication = indication,
            enabled = enabled,
            onClick = onClick,
        )
    } else Modifier
    GlassBox(
        modifier = modifier.then(clickModifier),
        shape = shape,
        backgroundColor = resolvedColor.copy(alpha = 0.65f),
        contentColor = resolvedContentColor,
        content = content,
    )
}

/**
 * 供信息流卡片把 `.background(cardBg())` 换成液态玻璃背景。
 * 普通 Modifier 扩展（非 @Composable），可用于任意 Modifier 链（含 run {} 块）。
 * 前置的 `.clip(...)` 保持不变，这里再补一层可折射的玻璃材质。
 */
fun Modifier.glassBackground(cardShape: Shape = MiuixShapes.medium): Modifier =
    this
        .clip(cardShape)
        .hazeGlass(input = HazeInput.Sources(GlassEnv.hazeState), style = CardGlassStyle)
