package com.example.c001apk.compose.ui.dyh

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import top.yukonga.miuix.kmp.basic.HorizontalDivider
import top.yukonga.miuix.kmp.basic.Scaffold
import top.yukonga.miuix.kmp.basic.TabRow
import androidx.compose.material3.Text
import top.yukonga.miuix.kmp.basic.TopAppBar
import com.example.c001apk.compose.ui.component.rememberHapticClick
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.dp
import com.example.c001apk.compose.ui.component.BackButton
import com.example.c001apk.compose.util.ReportType
import kotlinx.coroutines.launch

/**
 * Created by bggRGjQaUbCoE on 2024/6/12
 */
@Composable
fun DyhScreen(
    onBackClick: () -> Unit,
    id: String,
    title: String,
    onViewUser: (String) -> Unit,
    onViewFeed: (String, Boolean) -> Unit,
    onOpenLink: (String, String?) -> Unit,
    onCopyText: (String?) -> Unit,
    onReport: (String, ReportType) -> Unit,
) {

    val tabList = listOf("精选", "广场")
    val typeList = listOf("all", "square")
    val pagerState = rememberPagerState(
        pageCount = { tabList.size }
    )
    val layoutDirection = LocalLayoutDirection.current
    val scope = rememberCoroutineScope()
    var refreshState by remember { mutableStateOf(false) }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                navigationIcon = {
                    BackButton { onBackClick() }
                },
                title = title,
            )
        }
    ) { paddingValues ->

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = paddingValues.calculateTopPadding())
        ) {
            TabRow(
                modifier = Modifier
                    .padding(
                        start = paddingValues.calculateLeftPadding(layoutDirection),
                    ),
                tabs = tabList,
                selectedTabIndex = pagerState.currentPage,
                onTabSelected = { index ->
                    if (pagerState.currentPage == index) {
                        refreshState = true
                    }
                    scope.launch { pagerState.animateScrollToPage(index) }
                },
            )

            HorizontalDivider()

            HorizontalPager(state = pagerState) { index ->
                DyhContentScreen(
                    id = id,
                    type = typeList[index],
                    refreshState = refreshState,
                    resetRefreshState = { refreshState = false },
                    paddingValues = PaddingValues(
                        start = paddingValues.calculateLeftPadding(layoutDirection),
                        bottom = paddingValues.calculateBottomPadding(),
                    ),
                    onViewUser = onViewUser,
                    onViewFeed = onViewFeed,
                    onOpenLink = onOpenLink,
                    onCopyText = onCopyText,
                    onReport = onReport,
                )
            }
        }

    }

}
