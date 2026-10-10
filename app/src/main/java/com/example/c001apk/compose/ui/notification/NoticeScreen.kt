package com.example.c001apk.compose.ui.notification

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.shape.RoundedCornerShape
import top.yukonga.miuix.kmp.basic.Card
import top.yukonga.miuix.kmp.basic.CardDefaults
import top.yukonga.miuix.kmp.basic.Scaffold
import androidx.compose.material3.Text
import top.yukonga.miuix.kmp.basic.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.c001apk.compose.ui.component.BackButton
import com.example.c001apk.compose.ui.component.CommonScreen
import com.example.c001apk.compose.ui.ffflist.FFFContentViewModel
import com.example.c001apk.compose.util.ReportType
import com.example.c001apk.compose.util.makeToast
import top.yukonga.miuix.kmp.theme.MiuixTheme

/**
 * Created by bggRGjQaUbCoE on 2024/6/13
 */

enum class NoticeType {
    AT, COMMENT, LIKE, FOLLOW, MESSAGE
}

@Composable
fun NoticeScreen(
    onBackClick: () -> Unit,
    type: String,
    onViewUser: (String) -> Unit,
    onViewFeed: (String, Boolean) -> Unit,
    onOpenLink: (String, String?) -> Unit,
    onCopyText: (String?) -> Unit,
    onReport: (String, ReportType) -> Unit,
    onViewChat: (String, String, String) -> Unit,
) {

    val viewModel =
        hiltViewModel<NoticeViewModel, NoticeViewModel.ViewModelFactory>(key = type) { factory ->
            factory.create(
                url = when (type) {
                    NoticeType.AT.name -> "/v6/notification/atMeList"
                    NoticeType.COMMENT.name -> "/v6/notification/atCommentMeList"
                    NoticeType.LIKE.name -> "/v6/notification/feedLikeList"
                    NoticeType.FOLLOW.name -> "/v6/notification/contactsFollowList"
                    NoticeType.MESSAGE.name -> "/v6/message/list"
                    else -> throw IllegalArgumentException("invalid type: $type")
                }
            )
        }

    val context = LocalContext.current
    val layoutDirection = LocalLayoutDirection.current
    viewModel.toastText?.let {
        viewModel.resetToastText()
        context.makeToast(it)
    }
    var showMessageDialog by remember { mutableStateOf(false) }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                navigationIcon = {
                    BackButton { onBackClick() }
                },
                title = when (type) {
                            NoticeType.AT.name -> "@我的动态"
                            NoticeType.COMMENT.name -> "@我的评论"
                            NoticeType.LIKE.name -> "我收到的赞"
                            NoticeType.FOLLOW.name -> "好友关注"
                            NoticeType.MESSAGE.name -> "私信"
                            else -> throw IllegalArgumentException("invalid type: $type")
                        }
            )
        }
    ) { paddingValues ->

        CommonScreen(
            viewModel = viewModel,
            refreshState = null,
            resetRefreshState = {},
            paddingValues = PaddingValues(
                top = paddingValues.calculateTopPadding(),
                start = paddingValues.calculateLeftPadding(layoutDirection),
                bottom = paddingValues.calculateBottomPadding(),
            ),
            needTopPadding = true,
            onViewUser = onViewUser,
            onViewFeed = onViewFeed,
            onOpenLink = onOpenLink,
            onCopyText = onCopyText,
            onReport = onReport,
            onHandleMessage = { ukey, isTop ->
                viewModel.ukey = ukey
                viewModel.isTop = isTop
                showMessageDialog = true
            },
            onViewChat = { ukey, uid, username ->
                viewModel.resetUnRead(ukey)
                onViewChat(ukey, uid, username)
            }
        )
    }

    when {
        showMessageDialog -> {
            Dialog(onDismissRequest = { showMessageDialog = false }) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    cornerRadius = 28.dp,
                    colors = CardDefaults.defaultColors(
                        color = MiuixTheme.colorScheme.surfaceContainerHigh
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp)
                    ) {
                        Text(
                            text = if (viewModel.isTop == 1) "移除置顶" else "置顶",
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    showMessageDialog = false
                                    viewModel.onHandleMessage(FFFContentViewModel.ActionType.TOP)
                                }
                                .padding(horizontal = 24.dp, vertical = 14.dp),
                            style = MiuixTheme.textStyles.title3
                        )
                        Text(
                            text = "删除此对话",
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    showMessageDialog = false
                                    viewModel.onHandleMessage(FFFContentViewModel.ActionType.DELETE)
                                }
                                .padding(horizontal = 24.dp, vertical = 14.dp),
                            style = MiuixTheme.textStyles.title3
                        )
                    }
                }
            }
        }
    }

}
