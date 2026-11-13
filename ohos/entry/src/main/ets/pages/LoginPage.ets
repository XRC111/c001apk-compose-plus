import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { saveLogin } from '../common/CookieStore';

const DOMAIN = 0x0000;
/** 与 Android 版 Constants.URL_LOGIN 一致。 */
const LOGIN_URL: string = 'https://account.coolapk.com/auth/login?type=mobile';

/** 从 Cookie 串里取某个键的值。 */
function pickCookie(cookie: string, name: string): string {
  const parts = cookie.split(';');
  for (const raw of parts) {
    const s = raw.trim();
    const eq = s.indexOf('=');
    if (eq > 0 && s.substring(0, eq) === name) {
      return s.substring(eq + 1);
    }
  }
  return '';
}

@Entry
@Component
struct LoginPage {
  controller: webview.WebviewController = new webview.WebviewController();
  @State status: string = '请登录酷安账号';
  @State loggedIn: boolean = false;
  private busy: boolean = false;

  /** 页面每次加载完成后尝试提取登录 Cookie。 */
  private async captureCookies(): Promise<void> {
    if (this.busy || this.loggedIn) {
      return;
    }
    this.busy = true;
    try {
      // token / uid 一般挂在 .coolapk.com 域上，用主域取
      const cookies: string = await webview.WebCookieManager.fetchCookie('https://www.coolapk.com');
      const uid = pickCookie(cookies, 'uid');
      const username = pickCookie(cookies, 'username');
      const token = pickCookie(cookies, 'token');
      if (uid.length > 0 && token.length > 0) {
        await saveLogin(uid, username, token);
        this.loggedIn = true;
        this.status = username.length > 0 ? `已登录：${username}` : '已登录';
        setTimeout(() => {
          router.back();
        }, 800);
      } else {
        this.status = '尚未检测到登录态，请完成登录';
      }
    } catch (e) {
      hilog.error(DOMAIN, 'c001apk', 'fetchCookie failed: %{public}s', JSON.stringify(e));
      this.status = '读取 Cookie 失败，可稍后重试';
    }
    this.busy = false;
  }

  build() {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.ic_back'))
            .width(20)
            .height(20)
            .fillColor('#222222')
        }
        .width(34)
        .height(34)
        .borderRadius(17)
        .backgroundColor('#FFFFFF')
        .justifyContent(FlexAlign.Center)
        .onClick(() => router.back())
        Text('登录').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text(this.status)
        .fontSize(12)
        .fontColor(this.loggedIn ? '#2E7D32' : '#8A8A8E')
        .width('100%')
        .margin({ bottom: 8 })

      Web({ src: LOGIN_URL, controller: this.controller })
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .onPageEnd(() => {
          this.captureCookies();
        })
        .layoutWeight(1)
        .width('100%')

      Button('我已登录，手动提取 Cookie', { type: ButtonType.Normal })
        .fontSize(13)
        .margin({ top: 8 })
        .onClick(() => this.captureCookies())
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 40, bottom: 12 })
    .backgroundColor('#F2F2F6')
  }
}
