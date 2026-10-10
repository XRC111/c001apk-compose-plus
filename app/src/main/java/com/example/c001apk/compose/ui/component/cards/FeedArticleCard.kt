package com.example.c001apk.compose.ui.component.cards

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.c001apk.compose.logic.model.FeedArticleContentBean
import com.example.c001apk.compose.ui.component.LinkText
import com.example.c001apk.compose.ui.component.NineImageView
import com.example.c001apk.compose.util.longClick
import top.yukonga.miuix.kmp.theme.MiuixTheme
import com.example.c001apk.compose.ui.theme.MiuixShapes

/**
 * Created by bggRGjQaUbCoE on 2024/6/8
 */
@Composable
fun FeedArticleCard(
    item: FeedArticleContentBean,
    onOpenLink: (String, String?) -> Unit,
    onCopyText: (String) -> Unit,
) {

    when (item.type) {
        "text" -> {
            LinkText(
                text = item.message.orEmpty(),
                modifier = Modifier
                    .fillMaxWidth()
                    .longClick {
                        onCopyText(item.message.orEmpty())
                    }
                    .padding(horizontal = 16.dp)
                    .padding(top = 12.dp),
                lineSpacingMultiplier = 1.3f,
                textSize = 16f,
                onOpenLink = onOpenLink
            )
        }

        "image" -> {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .padding(top = 12.dp)
            ) {
                NineImageView(
                    pic = null,
                    picArr = listOf(item.url.orEmpty()),
                    feedType = null,
                    isSingle = true
                )
                if (!item.description.isNullOrEmpty()) {
                    Text(
                        text = item.description,
                        style = MiuixTheme.textStyles.title3.copy(fontSize = 13.sp),
                        color = MiuixTheme.colorScheme.outline,
                        modifier = Modifier
                            .padding(top = 4.dp)
                            .align(Alignment.CenterHorizontally),
                    )
                }
            }
        }

        "shareUrl" -> {
            Text(
                text = item.title.orEmpty(),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .padding(top = 12.dp)
                    .clip(MiuixShapes.medium)
                    .background(MiuixTheme.colorScheme.surfaceContainerHigh)
                    .clickable {
                        onOpenLink(item.url.orEmpty(), item.title)
                    }
                    .padding(10.dp),
                style = MiuixTheme.textStyles.title2.copy(fontSize = 14.sp)
            )
        }
    }
}
