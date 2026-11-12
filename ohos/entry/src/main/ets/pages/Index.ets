import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import { getDeviceCode } from '../common/DeviceCode';
import {
  feedSummary,
  feedTypeLabel,
  FeedItem,
  parseFeed,
  ParsedFeed,
  setPendingDetailId,
} from '../common/Feed';
import { setPendingCaptchaId } from '../common/CaptchaBridge';
import { clearLogin, currentUsername, isLoggedIn } from '../common/CookieStore';

@Entry
@Component
struct Index {
  @State statusText: string = '未请求';
  @State loading: boolean = false;
  @State tokenPreview: string = '';
  @State devicePreview: string = '';
  @State elapsedMs: number = 0;
  @State items: FeedItem[] = [];
  @State showRaw: boolean = false;
  @State rawPreview: string = '';
  @State loginName: string = '';
  @State captchaId: string = '';

  aboutToAppear(): void {
    // 进页面就把 v3 token 算出来，确认 bcrypt / MD5 / base64 链路在设备上跑通
    const t0 = Date.now();
    this.tokenPreview = CoolapkApi.currentTokenPreview();
    this.elapsedMs = Date.now() - t0;
    const dev = getDeviceCode();
    this.devicePreview = dev.length > 20 ? dev.substring(0, 20) + '…' : dev;
    this.refreshLogin();
  }

  /** 从登录页返回时刷新登录态。 */
  onPageShow(): void {
    this.refreshLogin();
  }

  private async refreshLogin(): Promise<void> {
    const logged = await isLoggedIn();
    if (logged) {
      this.loginName = await currentUsername();
    } else {
      this.loginName = '';
    }
  }

  private async logout(): Promise<void> {
    await clearLogin();
    this.loginName = '';
    this.statusText = '已退出登录';
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text('c001apk')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
          Text('HarmonyOS 原生 · ArkTS/ArkUI')
            .fontSize(11)
            .fontColor('#8A8A8E')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Button('设置', { type: ButtonType.Normal })
          .fontSize(13)
          .onClick(() => router.pushUrl({ url: 'pages/Settings' }))
        Button('关于', { type: ButtonType.Normal })
          .fontSize(13)
          .margin({ left: 8 })
          .onClick(() => router.pushUrl({ url: 'pages/About' }))
      }
      .width('100%')
      .padding({ bottom: 10 })

      // 账号行
      Row() {
        if (this.loginName.length > 0) {
          Text(`已登录：${this.loginName}`)
            .fontSize(12)
            .fontColor('#2E7D32')
          Blank()
          Button('退出', { type: ButtonType.Normal })
            .fontSize(12)
            .onClick(() => this.logout())
        } else {
          Text('未登录')
            .fontSize(12)
            .fontColor('#8A8A8E')
          Blank()
          Button('登录酷安', { type: ButtonType.Normal })
            .fontSize(12)
            .onClick(() => router.pushUrl({ url: 'pages/LoginPage' }))
        }
      }
      .width('100%')
      .margin({ bottom: 8 })

      // token 信息卡
      Column() {
        Row() {
          Text('X-App-Token v3')
            .fontSize(12)
            .fontColor('#666666')
          Blank()
          Text(`${this.elapsedMs} ms`)
            .fontSize(11)
            .fontColor('#8A8A8E')
        }
        .width('100%')

        Text(this.tokenPreview.length > 0 ? this.tokenPreview : '计算中…')
          .fontSize(10)
          .fontColor('#4A4A8A')
          .width('100%')
          .margin({ top: 4 })

        Text(`device: ${this.devicePreview}`)
          .fontSize(10)
          .fontColor('#8A8A8E')
          .width('100%')
          .margin({ top: 2 })
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .margin({ bottom: 10 })

      Row() {
        Button(this.loading ? '加载中…' : '加载首页', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(40)
          .enabled(!this.loading)
          .onClick(() => this.loadHome())
        Button('原始响应', { type: ButtonType.Normal })
          .fontSize(13)
          .height(40)
          .margin({ left: 8 })
          .onClick(() => {
            this.showRaw = !this.showRaw;
          })
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text(this.statusText)
        .fontSize(12)
        .fontColor(this.statusText.indexOf('风控') >= 0 ? '#E06030' : '#8A8A8E')
        .width('100%')
        .margin({ bottom: 6 })

      // 命中风控时提供验证入口
      if (this.captchaId.length > 0) {
        Row() {
          Text('需要人机验证才能继续')
            .fontSize(12)
            .fontColor('#E06030')
            .layoutWeight(1)
          Button('去验证', { type: ButtonType.Capsule })
            .fontSize(12)
            .height(32)
            .onClick(() => {
              setPendingCaptchaId(this.captchaId);
              router.pushUrl({ url: 'pages/CaptchaPage' });
            })
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#FFF3EF')
        .borderRadius(10)
        .margin({ bottom: 8 })
      }

      if (this.showRaw && this.rawPreview.length > 0) {
        Scroll() {
          Text(this.rawPreview)
            .fontSize(10)
            .fontColor('#555555')
            .width('100%')
        }
        .width('100%')
        .height(140)
        .padding(8)
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .margin({ bottom: 8 })
      }

      List({ space: 8 }) {
        ForEach(this.items, (item: FeedItem) => {
          ListItem() {
            Row() {
              Column() {
                Row() {
                  Text(feedTypeLabel(item))
                    .fontSize(10)
                    .fontColor('#FFFFFF')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .backgroundColor('#7A8CD0')
                    .borderRadius(4)
                  Blank()
                  Text(item.username !== undefined ? item.username : '')
                    .fontSize(10)
                    .fontColor('#8A8A8E')
                }
                .width('100%')

                Text(feedSummary(item))
                  .fontSize(13)
                  .width('100%')
                  .margin({ top: 6 })
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              if (item.pic !== undefined && item.pic.length > 0) {
                Image(item.pic)
                  .width(64)
                  .height(64)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .margin({ left: 10 })
              }
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .alignItems(VerticalAlign.Top)
            .onClick(() => {
              const feedId = item.id;
              if (feedId !== undefined && feedId.length > 0) {
                setPendingDetailId(feedId);
                router.pushUrl({ url: 'pages/FeedDetail' });
              }
            })
          }
        }, (item: FeedItem) => item.id !== undefined ? item.id : '')
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 40, bottom: 12 })
    .backgroundColor($r('app.color.page_background'))
  }

  private async loadHome(): Promise<void> {
    this.loading = true;
    this.statusText = '请求中…';
    this.captchaId = '';
    const res: CoolapkResponse = await CoolapkApi.fetchHome(1);
    const parsed: ParsedFeed = parseFeed(res.body);
    this.items = parsed.items;
    this.rawPreview = res.body.substring(0, Math.min(2000, res.body.length));
    this.loading = false;

    if (res.needCaptcha) {
      this.captchaId = res.captchaId;
      this.statusText = res.captchaId.length > 0
        ? '命中风控验证码，可点「去验证」完成人机验证'
        : '命中风控验证码，建议先导入 ShuzlmID 再试';
    } else if (res.status === 200 && parsed.items.length > 0) {
      this.statusText = `HTTP 200 · ${parsed.items.length} 条`;
    } else if (res.status === 200) {
      this.statusText = parsed.error.length > 0 ? `HTTP 200 · ${parsed.error}` : 'HTTP 200 · 无数据';
    } else if (res.status < 0) {
      this.statusText = '网络请求失败（检查网络或权限）';
    } else {
      this.statusText = `HTTP ${res.status}`;
    }
  }
}
