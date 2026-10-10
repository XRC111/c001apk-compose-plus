package com.example.c001apk.compose.ui.component.settings

import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.vector.ImageVector
import com.example.c001apk.compose.constant.Constants.EMPTY_STRING
import top.yukonga.miuix.kmp.basic.DropdownEntry
import top.yukonga.miuix.kmp.basic.DropdownItem
import top.yukonga.miuix.kmp.menu.OverlayDropdownMenu

/**
 * Used for selections
 * If label is null, then value will be displayed on the screen
 */
@Composable
fun <T> StateDropdownListItem(
    isEnable: Boolean = true,
    value: T?,
    leadingImageVector: ImageVector? = null,
    headlineText: String,
    selections: List<SelectionItem<T>>,
    onValueChanged: (index: Int, value: T) -> Unit,
) {
    OverlayDropdownMenu(
        entries = listOf(
            DropdownEntry(
                items = selections.mapIndexed { index, selection ->
                    DropdownItem(
                        text = selection.label,
                        selected = selection.value == value,
                        onClick = { onValueChanged(index, selection.value) },
                    )
                }
            )
        ),
        title = headlineText,
        summary = selections.find { it.value == value }?.label ?: EMPTY_STRING,
        startAction = if (leadingImageVector != null) {
            { Icon(imageVector = leadingImageVector, contentDescription = null) }
        } else {
            null
        },
        enabled = isEnable,
    )
}
