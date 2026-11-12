/**
 * 酷安网络协议层（HarmonyOS 原生平移）。
 *
 * 已从 Android 版平移并**验证**的部分：
 *  - Constants: VERSION_NAME / API_VERSION / VERSION_CODE / CHANNEL / MODE
 *  - X-App-Token v3（含 bcrypt、MD5、base64、AUTH_BLOB 切片）
 *  - X-App-Device 生成
 *  - 新版风控验证码（err_request_captcha_v2）的识别与错误返回
 *
 * 尚未闭环：
 *  - 易盾滑块验证页（Android 依赖 WebView + Activity；HarmonyOS 侧需接
 *    ArkUI 的 Web 组件并打通 cookie 回写，待后续迭代）
 *  - 登录态 Cookie（需先接入 Preferences 存 uid/token）
 */
import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { getTokenV3, APP_ID, VERSION_CODE, API_VERSION, CHANNEL, MODE, VERSION_NAME } from './CoolapkToken';
import { getDeviceCode } from './DeviceCode';

const DOMAIN = 0x0000;
const API_HOST: string = 'https://api.coolapk.com';
const REQUEST_WITH: string = 'XMLHttpRequest';
const LOCALE: string = 'zh-CN';

export interface CoolapkResponse {
  status: number;
  body: string;
  messageStatus: string;
  needCaptcha: boolean;
}

/** 组装与 Android 版 AddCookiesInterceptor 对齐的请求头。 */
export function buildHeaders(token: string, deviceCode: string): Record<string, string> {
  const headers: Record<string, string> = {
    'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 16; M2012K11AC a1b2c3d4e5f60718) ' +
      '(#Build; Xiaomi; M2012K11AC; a1b2c3d4e5f60718; 16) +CoolMarket/' +
      VERSION_NAME + '-' + VERSION_CODE + '-' + MODE,
    'X-Requested-With': REQUEST_WITH,
    'X-Sdk-Int': '36',
    'X-Sdk-Locale': LOCALE,
    'X-App-Id': APP_ID,
    'X-App-Token': token,
    'X-App-Version': VERSION_NAME,
    'X-App-Code': VERSION_CODE,
    'X-Api-Version': API_VERSION,
    'X-App-Device': deviceCode,
    'X-Dark-Mode': '0',
    'X-App-Channel': CHANNEL,
    'X-App-Mode': MODE,
    'X-App-Supported': VERSION_CODE,
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  return headers;
}

/** 从响应体里尽力提取 messageStatus（不引入完整 JSON 模型）。 */
function extractMessageStatus(body: string): string {
  const m = /"messageStatus"\s*:\s*"([^"]*)"/.exec(body);
  return m !== null ? m[1] : '';
}

export class CoolapkApi {
  /** 发起一次 GET，自动带上 v3 token。 */
  static async get(path: string): Promise<CoolapkResponse> {
    const deviceCode = getDeviceCode();
    const token = getTokenV3(deviceCode);
    const url = API_HOST + path;
    const req = http.createHttp();
    try {
      hilog.info(DOMAIN, 'c001apk', 'GET %{public}s', path);
      const res = await req.request(url, {
        method: http.RequestMethod.GET,
        header: buildHeaders(token, deviceCode),
        readTimeout: 15000,
        connectTimeout: 15000,
      });
      const raw = res.result;
      const body: string = typeof raw === 'string' ? raw : '';
      const messageStatus = extractMessageStatus(body);
      const needCaptcha = messageStatus === 'err_request_captcha_v2' ||
        body.indexOf('当前访问需要验证码') >= 0 ||
        body.indexOf('err_request_captcha_v2') >= 0;
      if (needCaptcha) {
        hilog.warn(DOMAIN, 'c001apk', '命中新版风控验证码，需要人机验证');
      }
      const r: CoolapkResponse = {
        status: res.responseCode,
        body: body,
        messageStatus: messageStatus,
        needCaptcha: needCaptcha,
      };
      return r;
    } catch (e) {
      hilog.error(DOMAIN, 'c001apk', 'GET %{public}s failed: %{public}s', path, JSON.stringify(e));
      const r: CoolapkResponse = { status: -1, body: '', messageStatus: '', needCaptcha: false };
      return r;
    } finally {
      req.destroy();
    }
  }

  /** 首页信息流，用于验证网络层与 token。 */
  static async fetchHome(page: number = 1): Promise<CoolapkResponse> {
    return CoolapkApi.get('/v6/main/indexV8?page=' + page.toString());
  }

  /** 动态详情。 */
  static async fetchFeedDetail(id: string): Promise<CoolapkResponse> {
    return CoolapkApi.get('/v6/feed/detail?id=' + encodeURIComponent(id));
  }

  /** 动态评论列表。 */
  static async fetchReplies(id: string, page: number = 1): Promise<CoolapkResponse> {
    const q = '/v6/feed/replyList?id=' + encodeURIComponent(id) +
      '&listType=lastupdate&page=' + page.toString() +
      '&discussMode=1&feedType=feed&blockStatus=0&fromInclude=0';
    return CoolapkApi.get(q);
  }

  /** 当前 v3 token（调试用，页面可展示前若干位确认算法生效）。 */
  static currentTokenPreview(): string {
    const token = getTokenV3(getDeviceCode());
    return token.length > 24 ? token.substring(0, 24) + '…' : token;
  }
}
