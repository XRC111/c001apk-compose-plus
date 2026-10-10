package com.example.c001apk.compose.ui.component

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import top.yukonga.miuix.kmp.basic.Text
import top.yukonga.miuix.kmp.theme.MiuixTheme

/**
 * 纯文字 + 短下划线的 TabRow，对齐酷安官方顶部导航样式。
 *
 * 为什么不用 MIUIX 的 [top.yukonga.miuix.kmp.basic.TabRow]：
 * MIUIX 的 TabRow 是「胶囊分段控件」形态 —— 每个未选中项会画 1dp 描边轮廓
 * （见其源码 TabItem 的 `squircleBorder(width = { if (isSelected) 0.dp else 1.dp })`），
 * 选中项则填充 squircle 胶囊。放在页面顶部会呈现「一排描边胶囊」，与酷安官方的
 * 「纯文字 + 短下划线」风格差异很大。MIUIX 没有提供纯文字变体，故在此自实现。
 *
 * @param tabs 各 tab 的文案
 * @param selectedTabIndex 当前选中索引
 * @param onTabSelected 选中回调
 * @param modifier 修饰符
 * @param indicatorColor 下划线颜色，默认取主题色
 * @param itemSpacing 相邻 tab 的间距
 * @param scrollable 是否可横向滚动（tab 较多时建议开启）
 */
@Composable
fun MiuixTextTabRow(
    tabs: List<String>,
    selectedTabIndex: Int,
    onTabSelected: (Int) -> Unit,
    modifier: Modifier = Modifier,
    indicatorColor: Color = MiuixTheme.colorScheme.primary,
    selectedTextColor: Color = MiuixTheme.colorScheme.onBackground,
    unselectedTextColor: Color = MiuixTheme.colorScheme.onSurfaceVariantSummary,
    itemSpacing: Dp = 20.dp,
    indicatorWidth: Dp = 18.dp,
    indicatorHeight: Dp = 3.dp,
    height: Dp = 42.dp,
    listState: LazyListState = rememberLazyListState(),
) {
    // tab 较多时自动滚到选中项，避免选中项在屏幕外
    LaunchedEffect(selectedTabIndex) {
        runCatching { listState.animateScrollToItem(selectedTabIndex) }
    }

    LazyRow(
        state = listState,
        modifier = modifier.height(height),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(itemSpacing),
    ) {
        items(tabs.size) { index ->
            val selected = index == selectedTabIndex
            TextTabItem(
                text = tabs[index],
                isSelected = selected,
                onClick = { if (!selected) onTabSelected(index) },
                indicatorColor = indicatorColor,
                selectedTextColor = selectedTextColor,
                unselectedTextColor = unselectedTextColor,
                indicatorWidth = indicatorWidth,
                indicatorHeight = indicatorHeight,
            )
        }
    }
}

@Composable
private fun TextTabItem(
    text: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    indicatorColor: Color,
    selectedTextColor: Color,
    unselectedTextColor: Color,
    indicatorWidth: Dp,
    indicatorHeight: Dp,
) {
    // 下划线宽度做一点动画，选中/取消都有过渡
    val animatedIndicatorWidth by animateDpAsState(
        targetValue = if (isSelected) indicatorWidth else 0.dp,
        animationSpec = tween(durationMillis = 180),
        label = "tabIndicatorWidth",
    )

    Box(
        modifier = Modifier
            .height(42.dp)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                text = text,
                color = if (isSelected) selectedTextColor else unselectedTextColor,
                style = MiuixTheme.textStyles.paragraph,
                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.height(3.dp))
            Box(
                modifier = Modifier
                    .width(animatedIndicatorWidth)
                    .height(indicatorHeight)
                    .clip(RoundedCornerShape(indicatorHeight / 2))
                    .background(if (isSelected) indicatorColor else Color.Transparent),
            )
        }
    }
}
