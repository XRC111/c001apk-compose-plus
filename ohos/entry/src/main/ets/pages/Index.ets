import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import { getDeviceCode } from '../common/DeviceCode';
import { feedSummary, feedTypeLabel, FeedItem, parseFeed, ParsedFeed } from '../common/Feed';

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

  aboutToAppear(): void {
    // 进页面就把 v3 token 算出来，确认 bcrypt / MD5 / base64 链路在设备上跑通
    const t0 = Date.now();
    this.tokenPreview = CoolapkApi.currentTokenPreview();
    this.elapsedMs = Date.now() - t0;
    const dev = getDeviceCode();
    this.devicePreview = dev.length > 20 ? dev.substring(0, 20) + '…' : dev;
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
            .width('100%')
            .padding(10)
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Start)
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
    const res: CoolapkResponse = await CoolapkApi.fetchHome(1);
    const parsed: ParsedFeed = parseFeed(res.body);
    this.items = parsed.items;
    this.rawPreview = res.body.substring(0, Math.min(2000, res.body.length));
    this.loading = false;

    if (res.needCaptcha) {
      this.statusText = '命中风控验证码（err_request_captcha_v2）：需人机验证或导入 ShuzlmID';
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
