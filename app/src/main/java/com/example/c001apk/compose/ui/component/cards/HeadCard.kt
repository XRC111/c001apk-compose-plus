package com.example.c001apk.compose.ui.component.cards

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import top.yukonga.miuix.kmp.basic.HorizontalDivider
import top.yukonga.miuix.kmp.basic.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import top.yukonga.miuix.kmp.theme.MiuixTheme

@Composable
fun HeadCard(
    title: String,
    description: String,
    modifier: Modifier = Modifier,
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        color = MiuixTheme.colorScheme.surfaceContainer,
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            if (title.isNotBlank()) {
                Text(
                    text = title,
                    style = MiuixTheme.textStyles.title1,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.height(14.dp))
                HorizontalDivider()
                Spacer(Modifier.height(14.dp))
            }
            Text(
                text = description.trim(),
                style = MiuixTheme.textStyles.body1,
                lineHeight = MiuixTheme.textStyles.body1.lineHeight * 1.2f,
            )
        }
    }
}
