package com.example.c001apk.compose.ui.component.settings

import top.yukonga.miuix.kmp.basic.Switch
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.vector.ImageVector
import com.example.c001apk.compose.ui.component.rememberHapticClick

@Composable
fun SwitchListItem(
    value: Boolean,
    leadingImageVector: ImageVector,
    headlineText: String,
    supportingText: String? = null,
    onValueChanged: (value: Boolean) -> Unit
) {
    val performHaptic = rememberHapticClick {}
    val toggle = rememberHapticClick {
        onValueChanged(!value)
    }
    BasicListItem(
        leadingImageVector = leadingImageVector,
        headlineText = headlineText,
        supportingText = supportingText,
        trailingContent = {
            Switch(
                checked = value,
                onCheckedChange = {
                    performHaptic()
                    onValueChanged(it)
                },
            )
        }
    ) {
        toggle()
    }
}
