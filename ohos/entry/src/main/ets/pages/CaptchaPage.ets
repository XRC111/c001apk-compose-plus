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

/** 与 Android 版 CaptchaActivity.BASE_URL 一致：易盾校验页面域名。 */
const BASE_URL: string = 'https://www.coolapk.com/';
/** 与 buildHeaders 的 User-Agent 一致，避免易盾看到默认 WebView UA。 */
const WEB_UA: string = 'Mozilla/5.0 (Linux; Android 16; M2012K11AC Build/a1b2c3d4e5f60718) ' +
  'AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/117 Mobile Safari/537.36 ' +
  'CoolMarket/16.6.4-2609291-community';

/**
 * 内嵌易盾验证页（对齐 Android 版 CaptchaActivity.buildHtml）。
 *
 * 关键：必须通过 loadData + baseUrl=https://www.coolapk.com/ 加载，
 * 而不是 $rawfile（resource:// 源）—— 易盾会校验页面域名与 captchaId 绑定域。
 */
function buildHtml(): string {
  return `<!doctype html><html lang="zh-CN"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<style>
  html,body{font:15px sans-serif;margin:0;padding:16px;background:#FFFFFF;color:#222}
  #status{font-size:13px;color:#8A8A8E;margin-bottom:12px;min-height:18px}
  #captcha{margin-top:4px}
</style></head><body>
<div id="status">正在准备验证组件…</div>
<div id="captcha"></div>
<script>
var _timeout=null;
function statusText(t){document.getElementById('status').innerHTML='<p>'+t+'</p>';}
function startCaptcha(captchaId){
  statusText('正在加载验证组件…');
  _timeout=setTimeout(function(){statusText('验证组件加载超时，请点「重新加载」');},15000);
  var old=document.getElementById('ne_script');
  if(old){old.parentNode.removeChild(old);}
  var script=document.createElement('script');
  script.id='ne_script';
  script.src='https://cstaticdun.126.net/load.min.js';
  script.onerror=function(){clearTimeout(_timeout);statusText('验证组件加载失败，请检查网络后重新加载');};
  script.onload=function(){
    if(typeof initNECaptcha!=='function'){clearTimeout(_timeout);statusText('验证组件不可用，请重新加载');return;}
    try{
      initNECaptcha({
        captchaId:captchaId,element:'#captcha',protocol:'https',
        mode:'embed',apiVersion:2,width:Math.min(320,window.innerWidth-32)+'px',lang:'zh-CN',
        onVerify:function(err,data){
          if(!err&&data&&data.validate){
            clearTimeout(_timeout);statusText('验证通过');
            if(window.CaptchaBridge&&window.CaptchaBridge.onVerified){
              window.CaptchaBridge.onVerified(data.validate);
            }else{
              statusText('验证通过但桥接不可用');
            }
          }else{statusText('验证未通过，请按提示重试');}
        }
      },function(){clearTimeout(_timeout);},function(){clearTimeout(_timeout);statusText('请按提示完成人机验证');});
    }catch(e){clearTimeout(_timeout);statusText('验证组件初始化失败，请重新加载');}
  };
  document.head.appendChild(script);
}
</script></body></html>`;
}

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
  private captchaId: string = '';
  private started: boolean = false;

  aboutToAppear(): void {
    this.captchaId = getPendingCaptchaId();
    setValidateCallback((validate: string) => {
      if (this.done) {
        return;
      }
      this.done = true;
      this.status = '验证通过，正在保存…';
      saveValidate(validate, this.captchaId).then(() => {
        this.status = '已保存验证凭证';
        // 通知所有页面：验证完成，可以重放刚才被拦的请求
        const prev: number | undefined = AppStorage.get<number>('captchaDoneTick');
        const tick: number = prev === undefined ? 0 : prev;
        AppStorage.setOrCreate('captchaDoneTick', tick + 1);
        setTimeout(() => {
          router.back();
        }, 700);
      });
    });
  }

  aboutToDisappear(): void {
    clearValidateCallback();
  }

  /** 加载易盾页并注入 captchaId。 */
  private loadCaptcha(): void {
    this.started = false;
    this.controller.loadData(buildHtml(), 'text/html', 'UTF-8', BASE_URL, BASE_URL);
  }

  private startIfNeeded(): void {
    if (this.started) {
      return;
    }
    this.started = true;
    if (this.captchaId.length > 0) {
      this.status = '请完成滑块验证';
      this.controller.runJavaScript(`startCaptcha('${this.captchaId}')`);
    } else {
      this.status = '缺少 captchaId，无法加载验证';
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

        Text('人机验证')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_title'))
          .margin({ left: 12 })
        Blank()

        Button('重新加载', { type: ButtonType.Normal })
          .fontSize(12)
          .height(32)
          .onClick(() => this.loadCaptcha())
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text(this.status)
        .fontSize(12)
        .fontColor(this.done ? $r('app.color.success') : $r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: 8 })

      Web({ src: '', controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .mixedMode(MixedMode.All)
        .userAgent(WEB_UA)
        .javaScriptProxy({
          object: this.bridge,
          name: 'CaptchaBridge',
          methodList: ['onVerified'],
          controller: this.controller,
        })
        .onControllerAttached(() => {
          this.loadCaptcha();
        })
        .onPageEnd(() => {
          this.startIfNeeded();
        })
        .onErrorReceive(() => {
          this.status = '验证页加载失败，请检查网络后重新加载';
        })
        .layoutWeight(1)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 40, bottom: 12 })
    .backgroundColor($r('app.color.page_bg'))
  }
}
