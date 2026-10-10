package com.example.c001apk.compose.ui.component.cards

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import top.yukonga.miuix.kmp.theme.MiuixTheme

/**
 * Created by bggRGjQaUbCoE on 2024/6/19
 */
@Composable
fun ChatTimeCard(
    modifier: Modifier = Modifier,
    title: String
) {

    Text(
        text = title,
        modifier = modifier
            .fillMaxWidth()
            .padding(12.dp),
        color = MiuixTheme.colorScheme.outline,
        style = MiuixTheme.textStyles.body2,
        textAlign = TextAlign.Center,
    )

}
