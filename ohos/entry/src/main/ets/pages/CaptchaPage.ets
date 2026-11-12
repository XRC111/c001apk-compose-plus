import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  clearValidateCallback,
  dispatchValidate,
  getPendingCaptchaId,
  setValidateCallback,
} from '../common/CaptchaBridge';
import { saveValidate } from '../common/CookieStore';

const DOMAIN = 0x0000;

/**
 * 暴露给网页的 JS 对象。
 * 易盾 onVerify 成功后，页面脚本调用 window.CaptchaBridge.onVerified(validate)。
 */
class CaptchaJsBridge {
  onVerified(validate: string): void {
    hilog.info(DOMAIN, 'c001apk', 'captcha verified, len=%{public}d', validate.length);
    dispatchValidate(validate);
  }
}

@Entry
@Component
struct CaptchaPage {
  controller: webview.WebviewController = new webview.WebviewController();
  private bridge: CaptchaJsBridge = new CaptchaJsBridge();
  @State status: string = '正在准备验证组件…';
  @State done: boolean = false;

  aboutToAppear(): void {
    setValidateCallback((validate: string) => {
      if (this.done) {
        return;
      }
      this.done = true;
      this.status = '验证通过，正在保存…';
      saveValidate(validate).then(() => {
        this.status = '已保存验证凭证';
        setTimeout(() => {
          router.back();
        }, 700);
      });
    });
  }

  aboutToDisappear(): void {
    clearValidateCallback();
  }

  build() {
    Column() {
      Row() {
        Button('<', { type: ButtonType.Normal }).onClick(() => router.back())
        Text('人机验证').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text(this.status)
        .fontSize(12)
        .fontColor(this.done ? '#2E7D32' : '#8A8A8E')
        .width('100%')
        .margin({ bottom: 8 })

      Web({ src: $rawfile('captcha.html'), controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .javaScriptProxy({
          object: this.bridge,
          name: 'CaptchaBridge',
          methodList: ['onVerified'],
          controller: this.controller,
        })
        .onPageEnd(() => {
          const cid = getPendingCaptchaId();
          if (cid.length > 0) {
            this.status = '请完成滑块验证';
            this.controller.runJavaScript(`startCaptcha('${cid}')`);
          } else {
            this.status = '缺少 captchaId，无法加载验证';
          }
        })
        .onErrorReceive(() => {
          this.status = '验证页加载失败，请检查网络';
        })
        .layoutWeight(1)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 40, bottom: 12 })
    .backgroundColor($r('app.color.page_background'))
  }
}
