package com.example.c001apk.compose.ui.ffflist

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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.example.c001apk.compose.constant.Constants.EMPTY_STRING
import com.example.c001apk.compose.ui.carousel.CarouselContentScreen
import com.example.c001apk.compose.ui.component.BackButton
import com.example.c001apk.compose.util.CookieUtil
import com.example.c001apk.compose.util.ReportType
import kotlinx.coroutines.launch
import top.yukonga.miuix.kmp.basic.TabRow

/**
 * Created by bggRGjQaUbCoE on 2024/6/12
 */

enum class FFFListType {
    FEED, FOLLOW, APK, USER_FOLLOW, FAN, RECENT, LIKE, REPLY, REPLYME, FAV, HISTORY, COLLECTION, COLLECTION_ITEM
}

@Composable
fun FFFListScreen(
    onBackClick: () -> Unit,
    uid: String?,
    type: String,
    id: String?,
    title: String?,
    onViewUser: (String) -> Unit,
    onViewFeed: (String, Boolean) -> Unit,
    onOpenLink: (String, String?) -> Unit,
    onCopyText: (String?) -> Unit,
    onReport: (String, ReportType) -> Unit,
    onViewFFFList: (String?, String, String?, String?) -> Unit,
) {

    val layoutDirection = LocalLayoutDirection.current
    val isMe by lazy { uid == CookieUtil.uid }
    val followList by lazy { listOf("用户", "话题", "数码", "应用") }
    val replyList by lazy { listOf("我的回复", "我收到的回复") }
    val pagerState = rememberPagerState {
        if (type == FFFListType.FOLLOW.name) followList.size
        else replyList.size
    }
    val tabList by lazy {
        if (type == FFFListType.FOLLOW.name) followList
        else replyList
    }
    var refreshState by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                navigationIcon = {
                    BackButton { onBackClick() }
                },
                title = title ?: when (type) { FFFListType.FEED.name -> "我的动态"; FFFListType.FOLLOW.name -> "我的关注"; FFFListType.USER_FOLLOW.name -> if (isMe) "我关注的人" else "TA关注的人"; FFFListType.FAN.name -> if (isMe) "关注我的人" else "TA的粉丝"; FFFListType.RECENT.name -> "我的常去"; FFFListType.LIKE.name -> "我的赞"; FFFListType.REPLY.name -> "我的回复"; FFFListType.COLLECTION.name -> "我的收藏"; else -> EMPTY_STRING }
            )
        }
    ) { paddingValues ->

        Column(
            modifier = Modifier.padding(top = paddingValues.calculateTopPadding())
        ) {
            when (type) {
                FFFListType.FOLLOW.name, FFFListType.REPLY.name -> {
                    TabRow(
                        modifier = Modifier.padding(
                            start = paddingValues.calculateLeftPadding(layoutDirection),
                            end = paddingValues.calculateRightPadding(layoutDirection),
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

                    HorizontalPager(
                        state = pagerState
                    ) { index ->
                        if (type == FFFListType.FOLLOW.name) {
                            when (index) {
                                0, 3 -> FFFContentScreen(
                                    id = id,
                                    uid = uid,
                                    type = if (index == 0) FFFListType.FOLLOW.name
                                    else FFFListType.APK.name,
                                    paddingValues = PaddingValues(
                                        start = paddingValues.calculateLeftPadding(layoutDirection),
                                        bottom = paddingValues.calculateBottomPadding(),
                                    ),
                                    refreshState = refreshState,
                                    resetRefreshState = { refreshState = false },
                                    onViewUser = onViewUser,
                                    onViewFeed = onViewFeed,
                                    onOpenLink = onOpenLink,
                                    onCopyText = onCopyText,
                                    onReport = onReport,
                                    onViewFFFList = onViewFFFList,
                                )

                                1, 2 -> CarouselContentScreen(
                                    url = if (index == 1) "#/topic/userFollowTagList"
                                    else "#/product/followProductList",
                                    title = if (index == 1) "我关注的话题"
                                    else "我关注的数码吧",
                                    paddingValues = paddingValues,
                                    refreshState = refreshState,
                                    resetRefreshState = { refreshState = false },
                                    onViewUser = onViewUser,
                                    onViewFeed = onViewFeed,
                                    onOpenLink = onOpenLink,
                                    onCopyText = onCopyText,
                                    onReport = onReport,
                                )
                            }
                        } else if (type == FFFListType.REPLY.name) {
                            FFFContentScreen(
                                id = id,
                                uid = uid,
                                type = if (index == 0) FFFListType.REPLY.name else FFFListType.REPLYME.name,
                                paddingValues = PaddingValues(
                                    start = paddingValues.calculateLeftPadding(layoutDirection),
                                    bottom = paddingValues.calculateBottomPadding(),
                                ),
                                refreshState = refreshState,
                                resetRefreshState = { refreshState = false },
                                onViewUser = onViewUser,
                                onViewFeed = onViewFeed,
                                onOpenLink = onOpenLink,
                                onCopyText = onCopyText,
                                onReport = onReport,
                                onViewFFFList = onViewFFFList,
                            )

                        }
                    }

                }

                else -> {
                    HorizontalDivider()
                    FFFContentScreen(
                        id = id,
                        uid = uid,
                        type = type,
                        paddingValues = PaddingValues(
                            start = paddingValues.calculateLeftPadding(layoutDirection),
                            bottom = paddingValues.calculateBottomPadding(),
                        ),
                        refreshState = null,
                        resetRefreshState = {},
                        onViewUser = onViewUser,
                        onViewFeed = onViewFeed,
                        onOpenLink = onOpenLink,
                        onCopyText = onCopyText,
                        onReport = onReport,
                        onViewFFFList = onViewFFFList,
                    )
                }
            }
        }

    }

}
