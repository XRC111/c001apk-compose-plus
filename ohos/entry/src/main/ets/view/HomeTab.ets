import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import {
  feedAvatar,
  feedPics,
  feedSummary,
  feedTypeLabel,
  FeedItem,
  parseFeed,
  ParsedFeed,
  setPendingAppId,
  setPendingDetailId,
  str,
  timeAgo,
} from '../common/Feed';
import { setPendingCaptchaId } from '../common/CaptchaBridge';

/** 与 Android 版 HomeScreen 的 TabType 顺序一致。 */
const TABS: string[] = ['关注', '应用', '动态', '热榜', '话题', '数码', '酷图'];
const TAB_FEED_INDEX: number = 2;

@Component
export struct HomeTab {
  @State selectedTab: number = TAB_FEED_INDEX;
  @State items: FeedItem[] = [];
  @State loading: boolean = false;
  @State refreshing: boolean = false;
  @State statusText: string = '';
  @State captchaId: string = '';
  @State pageNo: number = 1;
  @State hasMore: boolean = true;
  @State loadingMore: boolean = false;

  aboutToAppear(): void {
    this.loadHome();
  }

  build() {
    Column() {
      this.TopBar()
      this.TabStrip()

      if (this.selectedTab !== TAB_FEED_INDEX) {
        Column() {
          Text('该板块待接入')
            .fontSize(14)
            .fontColor('#9A9AA0')
          Text('目前「动态」板块已接通首页信息流')
            .fontSize(11)
            .fontColor('#C0C0C6')
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        this.CaptchaBanner()

        Refresh({ refreshing: $$this.refreshing }) {
          List({ space: 10 }) {
            // 空状态也放进 List，保证 Refresh 只有 List 一个子组件
            if (this.items.length === 0 && !this.loading) {
              ListItem() {
                Column() {
                  Text(this.statusText.length > 0 ? this.statusText : '暂无内容')
                    .fontSize(13)
                    .fontColor('#9A9AA0')
                }
                .width('100%')
                .height(300)
                .justifyContent(FlexAlign.Center)
              }
            }

            ForEach(this.items, (item: FeedItem) => {
              ListItem() {
                this.FeedCard(item)
              }
            }, (item: FeedItem) => str(item.id))

            ListItem() {
              this.Footer()
            }
          }
          .width('100%')
          .height('100%')
          .padding({ left: 12, right: 12, top: 6 })
          .scrollBar(BarState.Off)
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.loadHome();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F6')
  }

  // ==================== 顶部栏 ====================
  @Builder
  TopBar() {
    Row() {
      Text('酷安')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111111')
      Blank()
      Row() {
        Image($r('app.media.ic_search'))
          .width(20)
          .height(20)
          .fillColor('#333333')
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.Center)
      .onClick(() => router.pushUrl({ url: 'pages/SearchPage' }))
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 12 })
  }

  // ==================== 分类 Tab ====================
  @Builder
  TabStrip() {
    Scroll() {
      Row() {
        ForEach(TABS, (t: string, i: number) => {
          Column() {
            Text(t)
              .fontSize(this.selectedTab === i ? 16 : 15)
              .fontWeight(this.selectedTab === i ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.selectedTab === i ? '#FB7299' : '#66666B')
            Divider()
              .strokeWidth(3)
              .color(this.selectedTab === i ? '#FB7299' : Color.Transparent)
              .width(18)
              .margin({ top: 5 })
          }
          .margin({ right: 20 })
          .onClick(() => this.switchTab(i))
        }, (t: string) => t)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(44)
  }

  // ==================== 风控提示 ====================
  @Builder
  CaptchaBanner() {
    if (this.captchaId.length > 0) {
      Row() {
        Text('需要人机验证才能继续浏览')
          .fontSize(12)
          .fontColor('#D1532F')
          .layoutWeight(1)
        Button('去验证', { type: ButtonType.Capsule })
          .fontSize(12)
          .height(30)
          .backgroundColor('#FB7299')
          .onClick(() => {
            setPendingCaptchaId(this.captchaId);
            router.pushUrl({ url: 'pages/CaptchaPage' });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    }
  }

  // ==================== 信息流卡片 ====================
  @Builder
  FeedCard(item: FeedItem) {
    Column() {
      // 头部：头像 / 昵称 / 元信息
      Row() {
        if (feedAvatar(item).length > 0) {
          Image(feedAvatar(item))
            .width(40)
            .height(40)
            .borderRadius(20)
            .objectFit(ImageFit.Cover)
            .margin({ right: 10 })
        } else {
          Text(str(item.username).length > 0 ? str(item.username).substring(0, 1) : '?')
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor('#F2E8EC')
            .textAlign(TextAlign.Center)
            .fontSize(16)
            .fontColor('#FB7299')
            .margin({ right: 10 })
        }

        Column() {
          Text(str(item.username).length > 0 ? str(item.username) : '匿名用户')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111111')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row() {
            Text(feedTypeLabel(item))
              .fontSize(10)
              .fontColor('#8A8A90')
            Text(' · ')
              .fontSize(10)
              .fontColor('#C0C0C6')
            Text(timeAgo(item.dateline))
              .fontSize(10)
              .fontColor('#8A8A90')
          }
          .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 正文
      Text(feedSummary(item))
        .fontSize(15)
        .fontColor('#222222')
        .width('100%')
        .margin({ top: 10 })
        .maxLines(8)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(23)

      // 图片
      if (feedPics(item).length === 1) {
        Image(feedPics(item)[0])
          .width('100%')
          .constraintSize({ maxHeight: 240 })
          .objectFit(ImageFit.Cover)
          .borderRadius(10)
          .margin({ top: 10 })
      } else if (feedPics(item).length > 1) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(feedPics(item), (p: string) => {
            Image(p)
              .width(100)
              .height(100)
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
              .margin({ right: 6, bottom: 6 })
          }, (p: string) => p)
        }
        .width('100%')
        .margin({ top: 10 })
      }

      // 互动栏
      Row() {
        Row() {
          Image($r('app.media.ic_like'))
            .width(16)
            .height(16)
            .fillColor('#9A9AA0')
          Text(str(item.likenum).length > 0 ? str(item.likenum) : '赞')
            .fontSize(12)
            .fontColor('#9A9AA0')
            .margin({ left: 4 })
        }
        .margin({ right: 20 })

        Row() {
          Image($r('app.media.ic_comment'))
            .width(16)
            .height(16)
            .fillColor('#9A9AA0')
          Text(str(item.commentnum).length > 0 ? str(item.commentnum) : '评论')
            .fontSize(12)
            .fontColor('#9A9AA0')
            .margin({ left: 4 })
        }

        Blank()
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .alignItems(HorizontalAlign.Start)
    .shadow({ radius: 10, color: '#0D000000', offsetX: 0, offsetY: 2 })
    .onClick(() => this.openItem(item))
  }

  // ==================== 分页脚注 ====================
  @Builder
  Footer() {
    Row() {
      if (this.loadingMore) {
        LoadingProgress().width(18).height(18).color('#FB7299')
        Text('加载中…').fontSize(12).fontColor('#9A9AA0').margin({ left: 6 })
      } else if (this.hasMore) {
        Text('加载更多').fontSize(13).fontColor('#FB7299')
      } else {
        Text('没有更多了').fontSize(12).fontColor('#B0B0B6')
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 14, bottom: 18 })
    .onClick(() => this.loadMore())
  }

  // ==================== 逻辑 ====================
  private openItem(item: FeedItem): void {
    const id = item.id;
    if (id === undefined || id.length === 0) {
      return;
    }
    const et = item.entityType;
    if (et === 'product' || et === 'apk') {
      setPendingAppId(id);
      router.pushUrl({ url: 'pages/AppDetail' });
    } else {
      setPendingDetailId(id);
      router.pushUrl({ url: 'pages/FeedDetail' });
    }
  }

  private switchTab(i: number): void {
    this.selectedTab = i;
    if (i === TAB_FEED_INDEX && this.items.length === 0) {
      this.loadHome();
    }
  }

  private async loadHome(): Promise<void> {
    this.loading = true;
    this.captchaId = '';
    this.pageNo = 1;
    this.hasMore = true;
    const res: CoolapkResponse = await CoolapkApi.fetchHome(1);
    const parsed: ParsedFeed = parseFeed(res.body);
    this.items = parsed.items;
    this.loading = false;
    this.refreshing = false;

    if (res.needCaptcha) {
      this.captchaId = res.captchaId;
      this.statusText = '命中风控验证码';
    } else if (res.status === 200) {
      this.statusText = parsed.items.length > 0 ? '' : '暂无内容';
    } else if (res.status < 0) {
      this.statusText = '网络请求失败，下拉可重试';
    } else {
      this.statusText = `HTTP ${res.status}`;
    }
  }

  private async loadMore(): Promise<void> {
    if (this.loadingMore || !this.hasMore) {
      return;
    }
    this.loadingMore = true;
    const next = this.pageNo + 1;
    const res: CoolapkResponse = await CoolapkApi.fetchHome(next);
    const parsed: ParsedFeed = parseFeed(res.body);
    this.loadingMore = false;

    if (res.needCaptcha) {
      this.captchaId = res.captchaId;
      return;
    }
    if (parsed.items.length === 0) {
      this.hasMore = false;
      return;
    }
    this.pageNo = next;
    this.items = this.items.concat(parsed.items);
  }
}
