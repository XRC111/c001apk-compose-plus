import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import { currentUsername, isLoggedIn } from '../common/CookieStore';
import { FeedItem, parseFeed, ParsedFeed, setPendingChat, str, timeAgo } from '../common/Feed';
import { setPendingCaptchaId } from '../common/CaptchaBridge';

/** 通知分类：与 Android 版 NoticeType 一致。 */
const MSG_TABS: string[] = ['@我', '评论', '赞', '粉丝', '私信'];
const MSG_PATHS: string[] = [
  '/v6/notification/atMeList',
  '/v6/notification/atCommentMeList',
  '/v6/notification/feedLikeList',
  '/v6/notification/contactsFollowList',
  '/v6/message/list',
];

@Component
export struct MessageTab {
  @State loginName: string = '';
  @State loggedIn: boolean = false;
  @State selTab: number = 0;
  @State items: FeedItem[] = [];
  @State loading: boolean = false;
  @State status: string = '';
  @State unread: number = 0;
  @State captchaId: string = '';
  @State pageNo: number = 1;
  @State hasMore: boolean = true;
  @State loadingMore: boolean = false;

  aboutToAppear(): void {
    this.refresh();
  }

  private async refresh(): Promise<void> {
    this.loggedIn = await isLoggedIn();
    this.loginName = this.loggedIn ? await currentUsername() : '';
    if (this.loggedIn) {
      this.loadUnread();
      this.loadTab(this.selTab);
    }
  }

  private async loadUnread(): Promise<void> {
    const res: CoolapkResponse = await CoolapkApi.fetchCheckCount();
    const m = /"badge"\s*:\s*(\d+)/.exec(res.body);
    if (m !== null) {
      this.unread = parseInt(m[1], 10);
    }
  }

  private async loadTab(index: number): Promise<void> {
    this.loading = true;
    this.pageNo = 1;
    this.hasMore = true;
    this.status = '';
    this.captchaId = '';
    const res: CoolapkResponse = await CoolapkApi.fetchNotifications(MSG_PATHS[index], 1);
    const parsed: ParsedFeed = parseFeed(res.body);
    this.items = parsed.items;
    this.loading = false;

    if (res.needCaptcha) {
      this.captchaId = res.captchaId;
      this.status = '命中风控验证码，可点「去验证」继续';
    } else if (res.status === 200) {
      this.status = parsed.items.length > 0 ? '' : '暂无消息';
    } else if (res.status < 0) {
      this.status = '网络请求失败';
    } else {
      this.status = `HTTP ${res.status}`;
    }
  }

  @StorageProp('captchaDoneTick') @Watch('onCaptchaDone') captchaDoneTick: number = 0;

  /** 易盾验证完成后自动重放刚才被拦的请求。 */
  private onCaptchaDone(): void {
    this.loadTab(this.selTab);
  }

  build() {
    Column() {
      Row() {
        Text('消息')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_title'))
        if (this.unread > 0) {
          Text(this.unread > 99 ? '99+' : this.unread.toString())
            .fontSize(10)
            .fontColor('#FFFFFF')
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .backgroundColor($r('app.color.accent'))
            .borderRadius(8)
            .margin({ left: 8 })
        }
        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      if (!this.loggedIn) {
        Column() {
          Text('登录后查看消息')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Text('登录后可接收 @、回复、点赞、新粉丝通知')
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ top: 8 })
          Button('登录酷安', { type: ButtonType.Capsule })
            .fontSize(14)
            .width(160)
            .height(42)
            .margin({ top: 20 })
            .backgroundColor($r('app.color.accent'))
            .onClick(() => {
              router.pushUrl({ url: 'pages/LoginPage' }).then(() => {
                setTimeout(() => this.refresh(), 600);
              });
            })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Row() {
          ForEach(MSG_TABS, (t: string, i: number) => {
            Column() {
              Text(t)
                .fontSize(this.selTab === i ? 16 : 15)
                .fontWeight(this.selTab === i ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selTab === i
                  ? $r('app.color.accent')
                  : $r('app.color.text_secondary'))
              Divider()
                .strokeWidth(3)
                .color(this.selTab === i ? $r('app.color.accent') : Color.Transparent)
                .width(18)
                .margin({ top: 5 })
            }
            .margin({ right: 22 })
            .onClick(() => {
              this.selTab = i;
              this.loadTab(i);
            })
          }, (t: string) => t)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 6 })

        if (this.captchaId.length > 0) {
          Row() {
            Text('需要人机验证')
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
          .padding({ left: 16, right: 16, bottom: 8 })
        }

        if (this.loading) {
          Column() {
            LoadingProgress().width(30).height(30).color($r('app.color.accent'))
          }
          .width('100%')
          .height(90)
          .justifyContent(FlexAlign.Center)
        }

        List({ space: 8 }) {
          if (!this.loading && this.items.length === 0) {
            ListItem() {
              Column() {
                Text(this.status.length > 0 ? this.status : '暂无消息')
                  .fontSize(13)
                  .fontColor($r('app.color.text_tertiary'))
              }
              .width('100%')
              .height(260)
              .justifyContent(FlexAlign.Center)
            }
          }

          ForEach(this.items, (item: FeedItem) => {
            ListItem() {
              this.NoticeRow(item)
            }
            .onClick(() => {
              if (this.selTab === 4) {
                setPendingChat(str(item.ukey), this.nameOf(item));
                router.pushUrl({ url: 'pages/ChatPage' });
              }
            })
          }, (item: FeedItem) => str(item.id))
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12 })
        .scrollBar(BarState.Off)
        .contentEndOffset(12)
        .cachedCount(4)
        .onReachEnd(() => {
          this.loadMore();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  NoticeRow(item: FeedItem) {
    Row() {
      if (this.avatarOf(item).length > 0) {
        Image(this.avatarOf(item))
          .width(38)
          .height(38)
          .borderRadius(19)
          .objectFit(ImageFit.Cover)
              .alt($r('app.media.ic_image_placeholder'))
          .margin({ right: 10 })
      } else {
        Text(this.nameOf(item).length > 0 ? this.nameOf(item).substring(0, 1) : '?')
          .width(38)
          .height(38)
          .borderRadius(19)
          .backgroundColor($r('app.color.accent_soft'))
          .textAlign(TextAlign.Center)
          .fontSize(15)
          .fontColor($r('app.color.accent'))
          .margin({ right: 10 })
      }

      Column() {
        Row() {
          Text(this.nameOf(item))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_title'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(timeAgo(item.dateline))
            .fontSize(10)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ left: 8 })
        }
        .width('100%')

        Text(this.textOf(item))
          .fontSize(13)
          .fontColor($r('app.color.text_body'))
          .width('100%')
          .margin({ top: 5 })
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(20)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
    .alignItems(VerticalAlign.Top)
  }

  /** 触底加载下一页。 */
  private async loadMore(): Promise<void> {
    if (this.loadingMore || !this.hasMore) {
      return;
    }
    this.loadingMore = true;
    const next = this.pageNo + 1;
    const res: CoolapkResponse = await CoolapkApi.fetchNotifications(MSG_PATHS[this.selTab], next);
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

  private nameOf(item: FeedItem): string {
    const u = item.username;
    if (u !== undefined && u.length > 0) {
      return u;
    }
    const t = item.title;
    if (t !== undefined && t.length > 0) {
      return t;
    }
    return '系统通知';
  }

  private avatarOf(item: FeedItem): string {
    const a = item.userAvatar;
    if (a !== undefined && a.length > 0) {
      return a;
    }
    return '';
  }

  private textOf(item: FeedItem): string {
    const m = item.message;
    if (m !== undefined && m.length > 0) {
      return m;
    }
    return '(无内容)';
  }
}
