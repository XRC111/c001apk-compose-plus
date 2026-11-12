package com.example.c001apk.compose.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import top.yukonga.miuix.kmp.theme.MiuixTheme

val Purple80 = Color(0xFFD0BCFF)
val PurpleGrey80 = Color(0xFFCCC2DC)
val Pink80 = Color(0xFFEFB8C8)

val Purple40 = Color(0xFF6650a4)
val PurpleGrey40 = Color(0xFF625b71)
val Pink40 = Color(0xFF7D5260)

/**
 * 卡片底色：半透明，配合液态玻璃主题。
 * 简单链式背景已统一改用 glassBackground（真实折射），
 * 其余条件式 .background 调用点用本函数的半透明色兜底。
 */
@Composable
fun cardBg() = MiuixTheme.colorScheme.surfaceContainer.copy(alpha = 0.78f)
