package com.example.c001apk.compose.ui.search

import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import top.yukonga.miuix.kmp.basic.HorizontalDivider
import androidx.compose.material3.Icon
import top.yukonga.miuix.kmp.basic.RadioButton
import top.yukonga.miuix.kmp.basic.Scaffold
import androidx.compose.material3.Text
import top.yukonga.miuix.kmp.basic.TopAppBar
import com.example.c001apk.compose.ui.component.rememberHapticClick
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.c001apk.compose.ui.component.BackButton
import com.example.c001apk.compose.util.ReportType
import com.example.c001apk.compose.util.decode
import com.example.c001apk.compose.util.noRippleClickable
import kotlinx.coroutines.launch
import top.yukonga.miuix.kmp.theme.MiuixTheme
import top.yukonga.miuix.kmp.basic.TabRow
import top.yukonga.miuix.kmp.menu.OverlayIconCascadingDropdownMenu
import top.yukonga.miuix.kmp.basic.DropdownEntry
import top.yukonga.miuix.kmp.basic.DropdownItem

/**
 * Created by bggRGjQaUbCoE on 2024/6/9
 */

enum class SearchType {
    FEED, APP, GAME, PRODUCT, USER, TOPIC
}

enum class SearchFeedType {
    ALL, FEED, ARTICLE, COOLPIC, COMMENT, RATING, ANSWER, QUESTION, VOTE
}

enum class SearchOrderType {
    DATELINE, HOT, REPLY
}

private fun searchTypeTitle(type: SearchType): String {
    return when (type) {
        SearchType.FEED -> "动态"
        SearchType.APP -> "应用"
        SearchType.GAME -> "游戏"
        SearchType.PRODUCT -> "设备"
        SearchType.USER -> "用户"
        SearchType.TOPIC -> "话题"
    }
}

private fun searchFeedTitle(type: SearchFeedType): String {
    return when (type) {
        SearchFeedType.ALL -> "全部"
        SearchFeedType.FEED -> "动态"
        SearchFeedType.ARTICLE -> "文章"
        SearchFeedType.COOLPIC -> "酷图"
        SearchFeedType.COMMENT -> "评论"
        SearchFeedType.RATING -> "评分"
        SearchFeedType.ANSWER -> "回答"
        SearchFeedType.QUESTION -> "问题"
        SearchFeedType.VOTE -> "投票"
    }
}

private fun searchOrderTitle(type: SearchOrderType): String {
    return when (type) {
        SearchOrderType.DATELINE -> "时间"
        SearchOrderType.HOT -> "热度"
        SearchOrderType.REPLY -> "回复"
    }
}

private fun pageTypeTitle(pageType: String?): String? {
    if (pageType.isNullOrEmpty()) return pageType
    val match = SearchType.entries.firstOrNull { it.name.equals(pageType, ignoreCase = true) }
    return match?.let { searchTypeTitle(it) } ?: pageType
}

@Composable
fun SearchResultScreen(
    onBackClick: () -> Unit,
    keyword: String,
    title: String?,
    pageType: String?,
    pageParam: String?,
    onViewUser: (String) -> Unit,
    onViewFeed: (String, Boolean) -> Unit,
    onOpenLink: (String, String?) -> Unit,
    onCopyText: (String?) -> Unit,
    initialPage: Int = 0,
    updateInitPage: (Int) -> Unit,
    onReport: (String, ReportType) -> Unit,
) {

    val layoutDirection = LocalLayoutDirection.current
    val tabList = SearchType.entries
    val pagerState = rememberPagerState(
        initialPage = initialPage,
        pageCount = { if (pageType.isNullOrEmpty()) tabList.size else 1 }
    )
    var refreshState by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    var feedType by rememberSaveable { mutableStateOf(SearchFeedType.ALL) }
    var orderType by rememberSaveable { mutableStateOf(SearchOrderType.DATELINE) }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                navigationIcon = {
                    BackButton { onBackClick() }
                },
                title = keyword.decode,
                actions = {
                    androidx.compose.animation.AnimatedVisibility(
                        visible = pagerState.currentPage == 0,
                        enter = fadeIn(),
                        exit = fadeOut()
                    ) {
                        OverlayIconCascadingDropdownMenu(
                            entries = listOf(
                                DropdownEntry(
                                    items = listOf(
                                        DropdownItem(
                                            text = "类型",
                                            children = SearchFeedType.entries.map { feed ->
                                                DropdownItem(
                                                    text = searchFeedTitle(feed),
                                                    selected = feedType == feed,
                                                    onClick = { feedType = feed },
                                                )
                                            },
                                        ),
                                        DropdownItem(
                                            text = "排序",
                                            children = SearchOrderType.entries.map { order ->
                                                DropdownItem(
                                                    text = searchOrderTitle(order),
                                                    selected = orderType == order,
                                                    onClick = { orderType = order },
                                                )
                                            },
                                        ),
                                    )
                                )
                            ),
                        ) {
                            Icon(
                                imageVector = Icons.Default.MoreVert,
                                contentDescription = null,
                            )
                        }
                    }
                },
            )
        },
    ) { paddingValues ->

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = paddingValues.calculateTopPadding())
        ) {

            if (pageType.isNullOrEmpty()) {
                TabRow(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(
                            start = paddingValues.calculateLeftPadding(layoutDirection),
                        ),
                    tabs = tabList.map { searchTypeTitle(it) },
                    selectedTabIndex = pagerState.currentPage,
                    onTabSelected = { index ->
                        if (pagerState.currentPage == index) {
                            refreshState = true
                        }
                        scope.launch { pagerState.animateScrollToPage(index) }
                    },
                )
            }

            HorizontalDivider()

            HorizontalPager(
                state = pagerState
            ) { index ->
                SearchContentScreen(
                    searchType = SearchType.valueOf(SearchType.entries[index].name),
                    keyword = keyword.decode,
                    pageType = pageType,
                    pageParam = pageParam,
                    refreshState = refreshState,
                    resetRefreshState = {
                        refreshState = false
                    },
                    feedType = feedType,
                    orderType = orderType,
                    paddingValues = PaddingValues(
                        start = paddingValues.calculateLeftPadding(layoutDirection),
                        bottom = paddingValues.calculateBottomPadding(),
                    ),
                    onViewUser = onViewUser,
                    onViewFeed = onViewFeed,
                    onOpenLink = onOpenLink,
                    onCopyText = onCopyText,
                    updateInitPage = {
                        updateInitPage(pagerState.currentPage)
                    },
                    onReport = onReport,
                )
            }
        }

    }

}
