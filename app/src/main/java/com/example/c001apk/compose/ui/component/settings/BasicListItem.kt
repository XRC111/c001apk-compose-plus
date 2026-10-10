package com.example.c001apk.compose.ui.component.settings

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import top.yukonga.miuix.kmp.basic.BasicComponent
import top.yukonga.miuix.kmp.theme.MiuixTheme
import com.example.c001apk.compose.ui.theme.MiuixShapes

@Composable
fun BasicListItem(
    modifier: Modifier = Modifier,
    headlineText: String? = null,
    supportingText: String? = null,
    leadingImageVector: ImageVector? = null,
    leadingPainter: Painter? = null,
    leadingText: String? = null,
    trailingContent: @Composable () -> Unit = {},
    onClick: (() -> Unit)? = null,
) {
    BasicComponent(
        modifier = modifier,
        title = headlineText,
        summary = supportingText,
        startAction = if (leadingText != null) {
            {
                Text(
                    text = leadingText,
                    color = MiuixTheme.colorScheme.primary,
                    style = MiuixTheme.textStyles.title3,
                )
            }
        } else if (leadingImageVector != null) {
            { Icon(imageVector = leadingImageVector, contentDescription = null) }
        } else if (leadingPainter != null) {
            {
                Image(
                    painter = leadingPainter,
                    contentDescription = null,
                    modifier = Modifier
                        .clip(MiuixShapes.medium)
                        .size(24.dp),
                )
            }
        } else {
            null
        },
        endActions = { trailingContent() },
        onClick = onClick,
    )
}
