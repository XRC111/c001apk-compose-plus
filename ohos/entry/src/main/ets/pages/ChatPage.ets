import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import { getString, initSettings } from '../common/SettingsStore';
import { KEY_UID } from '../common/CookieStore';
import { common } from '@kit.AbilityKit';
import {
  FeedItem,
  getPendingChatName,
  getPendingChatUkey,
  parseFeed,
  ParsedFeed,
  str,
  timeAgo,
} from '../common/Feed';
import { setPendingCaptchaId } from '../common/CaptchaBridge';

@Entry
@Component
struct ChatPage {
  @State ukey: string = '';
  @State peerName: string = '';
  @State myUid: string = '';
  @State items: FeedItem[] = [];
  @State loading: boolean = false;
  @State status: string = '';
  @State captchaId: string = '';
  @State peerUid: string = '';
  @State draft: string = '';
  @State sending: boolean = false;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.ukey = getPendingChatUkey();
    this.peerName = getPendingChatName();
    this.load();
  }

  private async load(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await initSettings(ctx);
    this.myUid = await getString(KEY_UID, '');

    if (this.ukey.length === 0) {
      this.status = '缺少会话标识';
      return;
    }

    this.loading = true;
    this.status = '';
    const res: CoolapkResponse = await CoolapkApi.fetchChat(this.ukey, 1);
    const parsed: ParsedFeed = parseFeed(res.body);
    // 接口按时间倒序返回，翻成「上旧下新」
    this.items = parsed.items.slice().reverse();
    this.peekPeerUid(parsed.items);
    this.loading = false;

    if (res.needCaptcha) {
      this.captchaId = res.captchaId;
      this.status = '命中风控验证码，可点「去验证」继续';
    } else if (res.status === 200) {
      this.status = parsed.items.length > 0 ? '' : '还没有消息';
    } else if (res.status < 0) {
      this.status = '网络请求失败';
    } else {
      this.status = `HTTP ${res.status}`;
    }

    if (this.items.length > 0) {
      setTimeout(() => {
        this.scroller.scrollEdge(Edge.Bottom);
      }, 120);
    }
  }

  build() {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.ic_back'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.text_body'))
        }
        .width(34)
        .height(34)
        .borderRadius(17)
        .backgroundColor($r('app.color.card_bg'))
        .justifyContent(FlexAlign.Center)
        .onClick(() => router.back())

        Text(this.peerName.length > 0 ? this.peerName : '私信')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_title'))
          .margin({ left: 12 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
      }
      .width('100%')
      .height(52)
      .padding({ left: 12, right: 12 })

      if (this.status.length > 0) {
        Text(this.status)
          .fontSize(12)
          .fontColor(this.status.indexOf('风控') >= 0
            ? $r('app.color.danger')
            : $r('app.color.text_secondary'))
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      if (this.captchaId.length > 0) {
        Row() {
          Text('需要人机验证才能继续')
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

      List({ space: 10, scroller: this.scroller }) {
        ForEach(this.items, (item: FeedItem) => {
          ListItem() {
            this.Bubble(item)
          }
        }, (item: FeedItem) => str(item.id))
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12 })
      .scrollBar(BarState.Off)
      .contentEndOffset(16)
      .cachedCount(4)

      Row() {
        TextInput({ placeholder: '发消息…', text: this.draft })
          .layoutWeight(1)
          .height(38)
          .onChange((v: string) => {
            this.draft = v;
          })
          .onSubmit(() => {
            this.send();
          })
        Button(this.sending ? '发送中…' : '发送', { type: ButtonType.Capsule })
          .fontSize(13)
          .height(38)
          .margin({ left: 8 })
          .backgroundColor($r('app.color.accent'))
          .enabled(!this.sending)
          .onClick(() => {
            this.send();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 12 })
      .backgroundColor($r('app.color.card_bg'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  Bubble(item: FeedItem) {
    if (this.mine(item)) {
      Row() {
        Blank()
        Column() {
          Text(str(item.message))
            .fontSize(14)
            .fontColor('#FFFFFF')
            .padding({ left: 12, right: 12, top: 9, bottom: 9 })
            .backgroundColor($r('app.color.accent'))
            .borderRadius(12)
          Text(timeAgo(item.dateline))
            .fontSize(9)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.End)
        .constraintSize({ maxWidth: '74%' })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    } else {
      Row() {
        if (str(item.userAvatar).length > 0) {
          Image(item.userAvatar)
            .width(32)
            .height(32)
            .borderRadius(16)
            .objectFit(ImageFit.Cover)
            .alt($r('app.media.ic_image_placeholder'))
            .margin({ right: 8 })
        } else {
          Text(str(item.username).length > 0 ? str(item.username).substring(0, 1) : '?')
            .width(32)
            .height(32)
            .borderRadius(16)
            .backgroundColor($r('app.color.avatar_bg'))
            .textAlign(TextAlign.Center)
            .fontSize(13)
            .fontColor($r('app.color.chip_blue'))
            .margin({ right: 8 })
        }

        Column() {
          Text(str(item.message))
            .fontSize(14)
            .fontColor($r('app.color.text_body'))
            .padding({ left: 12, right: 12, top: 9, bottom: 9 })
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)
          Text(timeAgo(item.dateline))
            .fontSize(9)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .constraintSize({ maxWidth: '74%' })

        Blank()
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
  }

  /** 从会话记录里推断对方 uid（第一条非我方消息的 uid）。 */
  private peekPeerUid(items: FeedItem[]): void {
    if (this.peerUid.length > 0) {
      return;
    }
    for (const it of items) {
      const u = it.uid;
      if (u !== undefined && u.length > 0 && u !== this.myUid) {
        this.peerUid = u;
        return;
      }
    }
  }

  /** 发送一条文字私信。 */
  private async send(): Promise<void> {
    const text = this.draft.trim();
    if (text.length === 0 || this.sending) {
      return;
    }
    if (this.peerUid.length === 0) {
      this.status = '缺少对方 uid，暂时无法发送';
      return;
    }
    this.sending = true;
    const res: CoolapkResponse = await CoolapkApi.sendMessage(this.peerUid, text, '');
    this.sending = false;

    if (res.needCaptcha) {
      this.captchaId = res.captchaId;
      this.status = '发送被风控拦截，需先完成人机验证';
      return;
    }
    if (res.status === 200) {
      this.draft = '';
      this.status = '';
      this.load();
    } else if (res.status < 0) {
      this.status = '发送失败：网络错误';
    } else {
      this.status = `发送失败 HTTP ${res.status}`;
    }
  }

  private mine(item: FeedItem): boolean {
    const u = item.uid;
    if (u === undefined || u.length === 0 || this.myUid.length === 0) {
      return false;
    }
    return u === this.myUid;
  }
}
