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
  setPendingUid,
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
  @State statusText: string = '';
  @State captchaId: string = '';
  @State page: number = 1;
  @State hasMore: boolean = true;
  @State loadingMore: boolean = false;

  aboutToAppear(): void {
    this.loadHome();
  }

  build() {
    Column() {
      // ===== 顶部栏 =====
      Row() {
        Text('酷安')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')
        Blank()
        Button('搜索', { type: ButtonType.Normal })
          .fontSize(13)
          .height(32)
          .onClick(() => router.pushUrl({ url: 'pages/SearchPage' }))
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 12 })

      // ===== 分类 Tab（可横向滚动） =====
      Scroll() {
        Row() {
          ForEach(TABS, (t: string, i: number) => {
            Column() {
              Text(t)
                .fontSize(15)
                .fontWeight(this.selectedTab === i ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedTab === i ? '#FB7299' : '#666666')
              Divider()
                .strokeWidth(3)
                .color(this.selectedTab === i ? '#FB7299' : Color.Transparent)
                .width(18)
                .margin({ top: 5 })
            }
            .margin({ right: 18 })
            .onClick(() => this.switchTab(i))
          }, (t: string) => t)
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(42)

      // ===== 内容区 =====
      if (this.selectedTab !== TAB_FEED_INDEX) {
        Column() {
          Text('该板块待接入')
            .fontSize(13)
            .fontColor('#A0A0A6')
          Text('目前「动态」板块已接通首页信息流')
            .fontSize(11)
            .fontColor('#C0C0C6')
            .margin({ top: 6 })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        if (this.statusText.length > 0 && this.items.length === 0) {
          Text(this.statusText)
            .fontSize(12)
            .fontColor(this.statusText.indexOf('风控') >= 0 ? '#E06030' : '#8A8A8E')
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 6 })
        }

        if (this.captchaId.length > 0) {
          Row() {
            Text('需要人机验证')
              .fontSize(12)
              .fontColor('#E06030')
              .layoutWeight(1)
            Button('去验证', { type: ButtonType.Capsule })
              .fontSize(12)
              .height(30)
              .onClick(() => {
                setPendingCaptchaId(this.captchaId);
                router.pushUrl({ url: 'pages/CaptchaPage' });
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        }

        if (this.loading && this.items.length === 0) {
          Column() {
            LoadingProgress().width(32).height(32)
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 10 }) {
            ForEach(this.items, (item: FeedItem) => {
              ListItem() {
                this.FeedCard(item)
              }
            }, (item: FeedItem) => str(item.id))

            // 分页脚注
            ListItem() {
              Row() {
                if (this.loadingMore) {
                  LoadingProgress().width(18).height(18)
                  Text('加载中…').fontSize(12).fontColor('#8A8A8E').margin({ left: 6 })
                } else if (this.hasMore) {
                  Text('加载更多').fontSize(13).fontColor('#FB7299')
                } else {
                  Text('没有更多了').fontSize(12).fontColor('#A0A0A6')
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding({ top: 12, bottom: 12 })
              .onClick(() => this.loadMore())
            }
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 12, right: 12 })
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F7')
  }

  /** 信息流卡片：头像 + 昵称/时间 + 正文 + 九宫格 + 互动栏。 */
  @Builder
  FeedCard(item: FeedItem) {
    Column() {
      // 头部
      Row() {
        if (feedAvatar(item).length > 0) {
          Image(feedAvatar(item))
            .width(36)
            .height(36)
            .borderRadius(18)
            .objectFit(ImageFit.Cover)
            .margin({ right: 10 })
        } else {
          Text(str(item.username).length > 0 ? str(item.username).substring(0, 1) : '?')
            .width(36)
            .height(36)
            .borderRadius(18)
            .backgroundColor('#E8E8F0')
            .textAlign(TextAlign.Center)
            .fontSize(15)
            .fontColor('#7A8CD0')
            .margin({ right: 10 })
        }

        Column() {
          Text(str(item.username).length > 0 ? str(item.username) : '匿名用户')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#222222')
          Text(`${feedTypeLabel(item)} · ${timeAgo(item.dateline)}`)
            .fontSize(10)
            .fontColor('#A0A0A6')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 正文
      Text(feedSummary(item))
        .fontSize(14)
        .fontColor('#333333')
        .width('100%')
        .margin({ top: 10 })
        .maxLines(6)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(21)

      // 图片
      if (feedPics(item).length === 1) {
        Image(feedPics(item)[0])
          .width('100%')
          .constraintSize({ maxHeight: 220 })
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .margin({ top: 10 })
      } else if (feedPics(item).length > 1) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(feedPics(item), (p: string) => {
            Image(p)
              .width(96)
              .height(96)
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
              .margin({ right: 5, bottom: 5 })
          }, (p: string) => p)
        }
        .width('100%')
        .margin({ top: 10 })
      }

      // 互动栏
      Row() {
        Text(`赞 ${str(item.likenum).length > 0 ? str(item.likenum) : '0'}`)
          .fontSize(11)
          .fontColor('#8A8A8E')
        Text(`评论 ${str(item.commentnum).length > 0 ? str(item.commentnum) : '0'}`)
          .fontSize(11)
          .fontColor('#8A8A8E')
          .margin({ left: 16 })
        Blank()
        Text(feedTypeLabel(item))
          .fontSize(10)
          .fontColor('#FFFFFF')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('#7A8CD0')
          .borderRadius(4)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => this.openItem(item))
  }

  /** 按实体类型分流：应用进应用详情，其余进动态详情。 */
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
    this.page = 1;
    this.hasMore = true;
    const res: CoolapkResponse = await CoolapkApi.fetchHome(1);
    const parsed: ParsedFeed = parseFeed(res.body);
    this.items = parsed.items;
    this.loading = false;

    if (res.needCaptcha) {
      this.captchaId = res.captchaId;
      this.statusText = '命中风控验证码';
    } else if (res.status === 200) {
      this.statusText = parsed.items.length > 0 ? '' : '暂无内容';
    } else if (res.status < 0) {
      this.statusText = '网络请求失败';
    } else {
      this.statusText = `HTTP ${res.status}`;
    }
  }

  private async loadMore(): Promise<void> {
    if (this.loadingMore || !this.hasMore) {
      return;
    }
    this.loadingMore = true;
    const next = this.page + 1;
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
    this.page = next;
    this.items = this.items.concat(parsed.items);
  }
}
