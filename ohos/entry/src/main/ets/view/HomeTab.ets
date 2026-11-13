import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse, diagToken, diagTokenVersion, diagDevice } from '../common/CoolapkApi';
import {
  feedAvatar,
  feedPics,
  feedSummary,
  feedTypeLabel,
  FeedItem,
  parseFeed,
  ParsedFeed,
  picsOf,
  setPendingAppId,
  setPendingDetailId,
  str,
  timeAgo,
} from '../common/Feed';
import { setPendingCaptchaId } from '../common/CaptchaBridge';
import { setPendingImages } from '../pages/ImageViewer';
import { NetImage } from './NetImage';

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

  @StorageProp('captchaDoneTick') @Watch('onCaptchaDone') captchaDoneTick: number = 0;

  /** 易盾验证完成后自动重放刚才被拦的请求。 */
  private onCaptchaDone(): void {
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
            .fontColor($r('app.color.text_secondary'))
          Text('目前「动态」板块已接通首页信息流')
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
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
                    .fontColor($r('app.color.text_secondary'))
                }
                .width('100%')
                .height(300)
                .justifyContent(FlexAlign.Center)
              }
            }

            ForEach(this.items, (item: FeedItem) => {
              ListItem() {
                if (item.entityType === 'product' || item.entityType === 'apk') {
                  this.AppCard(item)
                } else {
                  this.FeedCard(item)
                }
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
          .contentEndOffset(12)
          .cachedCount(4)
          .onReachEnd(() => {
            this.loadMore();
          })
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.loadHome();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  // ==================== 顶部栏 ====================
  @Builder
  TopBar() {
    Row() {
      Text('酷安')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_title'))
      Blank()
      Row() {
        Image($r('app.media.ic_search'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.text_body'))
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor($r('app.color.card_bg'))
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
              .fontColor(this.selectedTab === i ? $r('app.color.accent') : $r('app.color.text_secondary'))
            Divider()
              .strokeWidth(3)
              .color(this.selectedTab === i ? $r('app.color.accent') : Color.Transparent)
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
          .fontColor($r('app.color.danger'))
          .layoutWeight(1)
        Button('去验证', { type: ButtonType.Capsule })
          .fontSize(12)
          .height(30)
          .backgroundColor($r('app.color.accent'))
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
        if (item.avatar !== undefined && item.avatar.length > 0) {
          NetImage({ url: str(item.avatar), imgWidth: 40, imgHeight: 40, radius: 20, fit: ImageFit.Cover })
            .margin({ right: 10 })
            .margin({ right: 10 })
        } else {
          Text(str(item.initial))
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('app.color.accent_soft'))
            .textAlign(TextAlign.Center)
            .fontSize(16)
            .fontColor($r('app.color.accent'))
            .margin({ right: 10 })
        }

        Column() {
          Text(str(item.usernameText))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_title'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row() {
            Text(str(item.typeLabel))
              .fontSize(10)
              .fontColor($r('app.color.text_secondary'))
            Text(' · ')
              .fontSize(10)
              .fontColor($r('app.color.text_tertiary'))
            Text(str(item.timeText))
              .fontSize(10)
              .fontColor($r('app.color.text_secondary'))
          }
          .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 正文
      Text(str(item.summary))
        .fontSize(15)
        .fontColor($r('app.color.text_body'))
        .width('100%')
        .margin({ top: 10 })
        .maxLines(8)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(23)

      // 图片
      if (picsOf(item).length === 1) {
        NetImage({ url: picsOf(item)[0], imgWidth: '100%', imgHeight: 200, radius: 10, fit: ImageFit.Cover })
          .margin({ top: 10 })
      } else if (picsOf(item).length > 1) {
        Grid() {
          ForEach(picsOf(item), (p: string) => {
            GridItem() {
              NetImage({ url: p, imgWidth: '100%', imgHeight: 100, radius: 8, fit: ImageFit.Cover })
                .borderRadius(8)
              .onClick(() => {
                setPendingImages(picsOf(item), picsOf(item).indexOf(p));
                router.pushUrl({ url: 'pages/ImageViewer' });
              })
            }
          }, (p: string) => p)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(6)
        .rowsGap(6)
        .height(this.gridHeight(picsOf(item).length, 100))
        .width('100%')
        .margin({ top: 10 })
      }

      // 互动栏
      Row() {
        Row() {
          Image($r('app.media.ic_like'))
            .width(16)
            .height(16)
            .fillColor($r('app.color.text_secondary'))
          Text(str(item.likeText))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 4 })
        }
        .margin({ right: 20 })

        Row() {
          Image($r('app.media.ic_comment'))
            .width(16)
            .height(16)
            .fillColor($r('app.color.text_secondary'))
          Text(str(item.commentText))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ left: 4 })
        }

        Blank()
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
    .alignItems(HorizontalAlign.Start)
    .shadow({ radius: 10, color: $r('app.color.shadow'), offsetX: 0, offsetY: 2 })
    .onClick(() => this.openItem(item))
  }
  // ==================== 应用卡片 ====================
  @Builder
  AppCard(item: FeedItem) {
    Column() {
      Row() {
        if (picsOf(item).length > 0) {
          NetImage({ url: picsOf(item)[0], imgWidth: 56, imgHeight: 56, radius: 12, fit: ImageFit.Cover })
            .margin({ right: 12 })
            .margin({ right: 12 })
        }

        Column() {
          Text(this.appTitle(item))
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_title'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.appMeta(item))
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
          Text(this.appDown(item))
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ top: 3 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Divider()
        .strokeWidth(0.5)
        .color($r('app.color.divider'))
        .margin({ top: 12, bottom: 10 })

      Row() {
        Text(this.appSummary(item))
          .fontSize(12)
          .fontColor($r('app.color.text_body'))
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('查看')
          .fontSize(12)
          .fontColor($r('app.color.accent'))
          .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
    .alignItems(HorizontalAlign.Start)
    .shadow({ radius: 10, color: $r('app.color.shadow'), offsetX: 0, offsetY: 2 })
    .onClick(() => this.openItem(item))
  }

  private appTitle(item: FeedItem): string {
    const n = item.apkname;
    if (n !== undefined && n.length > 0) {
      return n;
    }
    const t = item.title;
    if (t !== undefined && t.length > 0) {
      return t;
    }
    return '应用';
  }

  private appMeta(item: FeedItem): string {
    const parts: string[] = [];
    const v = item.apkversionname;
    if (v !== undefined && v.length > 0) {
      parts.push('版本 ' + v);
    }
    const s = item.apksize;
    if (s !== undefined && s.length > 0) {
      parts.push(s);
    }
    return parts.join(' · ');
  }

  private appDown(item: FeedItem): string {
    const d = item.downCount;
    if (d !== undefined && d.length > 0) {
      return d + ' 次下载';
    }
    const n = item.downnum;
    if (n !== undefined && n.length > 0) {
      return n + ' 次下载';
    }
    return '';
  }

  private appSummary(item: FeedItem): string {
    const m = item.message;
    if (m !== undefined && m.length > 0) {
      return m;
    }
    return '点击查看应用详情';
  }


  // ==================== 分页脚注 ====================
  @Builder
  Footer() {
    Row() {
      if (this.loadingMore) {
        LoadingProgress().width(18).height(18).color($r('app.color.accent'))
        Text('加载中…').fontSize(12).fontColor($r('app.color.text_secondary')).margin({ left: 6 })
      } else if (this.hasMore) {
        Text('加载更多').fontSize(13).fontColor($r('app.color.accent'))
      } else {
        Text('没有更多了').fontSize(12).fontColor($r('app.color.text_tertiary'))
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
      // 有 data 但为空才是真的"暂无内容"；解析失败要把原因显示出来，
      // 否则 1004「请求未验证」这类问题会被误判成"没内容"
      if (parsed.items.length > 0) {
        this.statusText = '';
      } else if (parsed.error.length > 0) {
        // 真机诊断：把 token 前缀与设备码一并显示，不用抓日志也能定位
        this.statusText = parsed.error + '\nver=' + diagTokenVersion() + ' token=' + diagToken() + '\ndev=' + diagDevice().substring(0, 30);
      } else {
        this.statusText = '暂无内容';
      }
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

  /** 九宫格高度：3 列，单元格 cell 高，行间距 6。 */
  private gridHeight(n: number, cell: number): number {
    const rows = Math.ceil(n / 3);
    if (rows <= 0) {
      return 0;
    }
    return rows * cell + (rows - 1) * 6;
  }
}
