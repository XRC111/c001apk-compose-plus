import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import { getDeviceCode } from '../common/DeviceCode';

@Entry
@Component
struct Index {
  @State statusText: string = '未请求';
  @State responsePreview: string = '';
  @State loading: boolean = false;
  @State tokenPreview: string = '';
  @State devicePreview: string = '';
  @State elapsedMs: number = 0;

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
      Text('c001apk')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 6 })
      Text('HarmonyOS 原生 (ArkTS / ArkUI · Stage)')
        .fontSize(13)
        .fontColor('#8A8A8E')
        .margin({ bottom: 20 })

      // token 信息卡
      Column() {
        Row() {
          Text('X-App-Token v3').fontSize(13).fontWeight(FontWeight.Medium)
          Blank()
          Text(`${this.elapsedMs} ms`).fontSize(12).fontColor('#8A8A8E')
        }
        .width('100%')
        Text(this.tokenPreview.length > 0 ? this.tokenPreview : '计算中…')
          .fontSize(11)
          .fontColor('#4A4A8A')
          .width('100%')
          .margin({ top: 6 })
        Text(`device: ${this.devicePreview}`)
          .fontSize(11)
          .fontColor('#8A8A8E')
          .width('100%')
          .margin({ top: 4 })
      }
      .width('90%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ bottom: 18 })

      Button('测试酷安接口 /v6/main/indexV8', { type: ButtonType.Capsule })
        .width('86%')
        .height(44)
        .onClick(() => this.loadHome())

      if (this.loading) {
        LoadingProgress().width(36).height(36).margin({ top: 16 })
      }

      Text(this.statusText)
        .fontSize(14)
        .margin({ top: 16 })
        .fontColor(this.statusText.indexOf('风控') >= 0 ? '#E06030' : '#333333')

      if (this.responsePreview.length > 0) {
        Scroll() {
          Text(this.responsePreview)
            .fontSize(11)
            .fontColor('#555555')
            .width('100%')
        }
        .width('90%')
        .height(180)
        .padding(10)
        .margin({ top: 12 })
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
      }

      Blank()

      Row() {
        Button('设置', { type: ButtonType.Normal })
          .onClick(() => router.pushUrl({ url: 'pages/Settings' }))
        Button('关于', { type: ButtonType.Normal })
          .margin({ left: 12 })
          .onClick(() => router.pushUrl({ url: 'pages/About' }))
      }
      .margin({ bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .padding({ top: 48, left: 20, right: 20 })
    .backgroundColor($r('app.color.page_background'))
  }

  private async loadHome(): Promise<void> {
    this.loading = true;
    this.statusText = '请求中…';
    const res: CoolapkResponse = await CoolapkApi.fetchHome(1);
    this.loading = false;
    if (res.needCaptcha) {
      this.statusText = '命中风控验证码（err_request_captcha_v2）：需完成人机验证或导入 ShuzlmID';
    } else if (res.status === 200) {
      this.statusText = `请求成功 HTTP 200（${res.body.length} 字节）`;
    } else {
      this.statusText = `请求结束 HTTP ${res.status}`;
    }
    this.responsePreview = res.body.slice(0, 1200);
  }
}
