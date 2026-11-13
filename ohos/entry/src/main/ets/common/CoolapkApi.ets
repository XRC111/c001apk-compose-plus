/**
 * 酷安网络协议层（HarmonyOS 原生平移）。
 *
 * 已从 Android 版平移并**验证**的部分：
 *  - Constants: VERSION_NAME / API_VERSION / VERSION_CODE / CHANNEL / MODE
 *  - X-App-Token v3（含 bcrypt、MD5、base64、AUTH_BLOB 切片）
 *  - X-App-Device 生成
 *  - 新版风控验证码（err_request_captcha_v2）的识别与 captchaId 提取
 *  - Cookie：登录态（uid/username/token）+ SESSID + validate
 */
import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { getTokenV3, APP_ID, VERSION_CODE, API_VERSION, CHANNEL, MODE, VERSION_NAME } from './CoolapkToken';
import { getDeviceCode } from './DeviceCode';
import { buildCookieHeaderSync, saveSessid, withProofSync,
  clearValidate, saveCaptchaField, inReplayWindowSync } from './CookieStore';
import { parseChallenge, DEFAULT_CAPTCHA_FIELD } from './CaptchaChallenge';

const DOMAIN = 0xD0001;
const API_HOST: string = 'https://api.coolapk.com';
const REQUEST_WITH: string = 'XMLHttpRequest';
const LOCALE: string = 'zh-CN';

export interface CoolapkResponse {
  status: number;
  body: string;
  messageStatus: string;
  needCaptcha: boolean;
  /** 命中风控时服务端下发的易盾 captchaId；解析不到时用默认 ID。 */
  captchaId: string;
  /** 重放请求需要携带的字段名（如 _v2_post_token）。 */
  captchaField: string;
}

/** 组装与 Android 版 AddCookiesInterceptor 对齐的请求头。 */
export function buildHeaders(token: string, deviceCode: string, cookie: string): Record<string, string> {
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
  if (cookie.length > 0) {
    headers['Cookie'] = cookie;
  }
  return headers;
}

/** 从响应体里尽力提取 messageStatus（不引入完整 JSON 模型）。 */
function extractMessageStatus(body: string): string {
  const m = /"messageStatus"\s*:\s*"([^"]*)"/.exec(body);
  return m !== null ? m[1] : '';
}

/** 从 Set-Cookie 串里取某个 Cookie 的值。 */
function extractCookieValue(cookies: string, name: string): string {
  const parts = cookies.split(';');
  for (const raw of parts) {
    const s = raw.trim();
    const eq = s.indexOf('=');
    if (eq > 0 && s.substring(0, eq) === name) {
      return s.substring(eq + 1);
    }
  }
  return '';
}

/** 统一构造响应对象。 */
function makeResponse(status: number, body: string): CoolapkResponse {
  const ch = parseChallenge(body);
  const r: CoolapkResponse = {
    status: status,
    body: body,
    messageStatus: extractMessageStatus(body),
    needCaptcha: ch !== null,
    captchaId: ch !== null ? ch.captchaId : '',
    captchaField: ch !== null ? ch.field : DEFAULT_CAPTCHA_FIELD,
  };
  return r;
}

/**
 * 统一处理风控响应：命中时清掉失效的 NEC 凭证、记住本次挑战的 field。
 * GET / POST / 表单 / multipart 都必须调用，否则验证成功后旧凭证会一直
 * 被带上，导致「验证 → 再被拦」的死循环。
 */
async function handleChallenge(r: CoolapkResponse): Promise<CoolapkResponse> {
  if (r.needCaptcha) {
    await clearValidate();
    await saveCaptchaField(r.captchaField);
    hilog.warn(DOMAIN, 'c001apk', '命中新版风控验证码 captchaId=%{public}s field=%{public}s',
      r.captchaId, r.captchaField);
  }
  // 成功时不清凭证：Android 版让 validate Cookie 在整个会话内持续生效
  return r;
}

/**
 * v3 token 的短期缓存。
 *
 * 生成一次 token 需要一次 bcrypt(cost=10)，在手机上约数百毫秒；
 * 列表滚动时会连续发多个请求，逐个重算会明显卡顿。
 * token 内部带时间戳，服务端只校验新鲜度，缓存 60 秒（token 内含时间戳，服务端只校验新鲜度）。
 */
let cachedToken: string = '';
let cachedTokenAt: number = 0;
let cachedTokenDevice: string = '';

function tokenFor(deviceCode: string): string {
  const now = Date.now();
  if (cachedToken.length > 0 && cachedTokenDevice === deviceCode && now - cachedTokenAt < 60000) {
    return cachedToken;
  }
  const t = getTokenV3(deviceCode);
  cachedToken = t;
  cachedTokenAt = now;
  cachedTokenDevice = deviceCode;
  return t;
}

export class CoolapkApi {
  /** 发起一次 GET，自动带上 v3 token 与本地 Cookie。 */
  static async get(path: string): Promise<CoolapkResponse> {
    const deviceCode = getDeviceCode();
    const token = tokenFor(deviceCode);
    // 全部同步取值，不做任何磁盘/跨线程 IO（这是列表卡顿的主因之一）
    const cookie = buildCookieHeaderSync();
    const replay = inReplayWindowSync();
    const finalPath = withProofSync(path, replay);
    const url = API_HOST + finalPath;
    const req = http.createHttp();
    try {
      hilog.info(DOMAIN, 'c001apk', 'GET %{public}s device=%{public}s token=%{public}s',
        path, deviceCode, token.substring(0, Math.min(16, token.length)));
      hilog.info(DOMAIN, 'c001apk', 'tokenPrefix=%{public}s tokenLen=%{public}d',
        token.substring(0, Math.min(2, token.length)), token.length);
      const res = await req.request(url, {
        method: http.RequestMethod.GET,
        header: buildHeaders(token, deviceCode, cookie),
        readTimeout: 15000,
        connectTimeout: 15000,
      });
      const raw = res.result;
      const body: string = typeof raw === 'string' ? raw : '';
      // 真机诊断：把 HTTP 码与响应体前 200 字符打出来，定位 1004/403/风控
      hilog.info(DOMAIN, 'c001apk', 'GET %{public}s -> %{public}d body=%{public}s',
        path, res.responseCode, body.substring(0, Math.min(200, body.length)));

      // 服务端下发的 SESSID 必须带回后续请求，风控重放才有效
      const respCookies: string = res.cookies !== undefined ? res.cookies : '';
      if (respCookies.length > 0) {
        const sessid = extractCookieValue(respCookies, 'SESSID');
        if (sessid.length > 0) {
          await saveSessid('SESSID=' + sessid);
        }
      }

      // 成功时不清凭证：Android 版让 validate Cookie 在整个会话内持续生效
      return await handleChallenge(makeResponse(res.responseCode, body));
    } catch (e) {
      hilog.error(DOMAIN, 'c001apk', 'GET %{public}s failed: %{public}s', path, JSON.stringify(e));
      return makeResponse(-1, '');
    } finally {
      req.destroy();
    }
  }

  /** 发起一次 POST（无 body，参数在 query 上）。 */
  static async post(path: string): Promise<CoolapkResponse> {
    const deviceCode = getDeviceCode();
    const token = tokenFor(deviceCode);
    const cookie = buildCookieHeaderSync();
    // POST 命中风控后同样需要带凭证重放（对齐 Android 版 buildRetry 对 POST 的处理）
    const replay = inReplayWindowSync();
    const url = API_HOST + withProofSync(path, replay);
    const req = http.createHttp();
    try {
      const res = await req.request(url, {
        method: http.RequestMethod.POST,
        header: buildHeaders(token, deviceCode, cookie),
        readTimeout: 15000,
        connectTimeout: 15000,
      });
      const raw = res.result;
      const body: string = typeof raw === 'string' ? raw : '';
      return await handleChallenge(makeResponse(res.responseCode, body));
    } catch (e) {
      hilog.error(DOMAIN, 'c001apk', 'POST %{public}s failed: %{public}s', path, JSON.stringify(e));
      return makeResponse(-1, '');
    } finally {
      req.destroy();
    }
  }

  /**
   * 发起一次表单 POST（application/x-www-form-urlencoded）。
   * 用于评论发送等需要 @FieldMap 的接口。
   */
  /**
   * 发起一次表单 POST（application/x-www-form-urlencoded）。
   * @param body 已 urlencode 的表单体，如 "message=hi&replyAndForward=0"
   */
  static async postForm(path: string, body: string): Promise<CoolapkResponse> {
    const deviceCode = getDeviceCode();
    const token = tokenFor(deviceCode);
    const cookie = buildCookieHeaderSync();
    // 评论发送等表单 POST 也要支持风控重放
    const replay = inReplayWindowSync();
    const url = API_HOST + withProofSync(path, replay);
    const req = http.createHttp();
    try {
      const res = await req.request(url, {
        method: http.RequestMethod.POST,
        header: buildHeaders(token, deviceCode, cookie),
        extraData: body,
        readTimeout: 15000,
        connectTimeout: 15000,
      });
      const raw = res.result;
      const text: string = typeof raw === 'string' ? raw : '';
      return await handleChallenge(makeResponse(res.responseCode, text));
    } catch (e) {
      hilog.error(DOMAIN, 'c001apk', 'postForm %{public}s failed: %{public}s', path, JSON.stringify(e));
      return makeResponse(-1, '');
    } finally {
      req.destroy();
    }
  }

  /**
   * 发送评论（对齐 Android 版 ReplyActivity / ApiService.postReply）。
   *
   * POST v6/feed/reply?id=<feedId>&type=feed
   * 表单：message=<正文>&replyAndForward=<0|1>
   */
  /** 评论表单（ArkTS 不允许无类型对象字面量，需显式接口）。 */
  static async postReply(feedId: string, message: string, replyAndForward: string = '0'): Promise<CoolapkResponse> {
    const body: string = 'message=' + encodeURIComponent(message) +
      '&replyAndForward=' + encodeURIComponent(replyAndForward);
    return CoolapkApi.postForm(
      '/v6/feed/reply?id=' + encodeURIComponent(feedId) + '&type=feed', body);
  }

  /** 首页信息流。 */
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

  /**
   * 搜索。
   * @param type feed / app / user / topic 等
   */
  static async fetchSearch(keyword: string, type: string = 'feed', page: number = 1): Promise<CoolapkResponse> {
    const q = '/v6/search?type=' + type +
      '&feedType=feed&sort=default' +
      '&searchValue=' + encodeURIComponent(keyword) +
      '&page=' + page.toString() +
      '&showAnonymous=-1';
    return CoolapkApi.get(q);
  }

  /** 应用详情（id 为包名）。 */
  static async fetchAppDetail(packageName: string): Promise<CoolapkResponse> {
    return CoolapkApi.get('/v6/apk/detail?id=' + encodeURIComponent(packageName) + '&installed=1');
  }

  /** 用户主页。 */
  static async fetchUserProfile(uid: string): Promise<CoolapkResponse> {
    return CoolapkApi.get('/v6/user/profile?uid=' + encodeURIComponent(uid));
  }

  /** 未读数（登录后可用）。 */
  static async fetchCheckCount(): Promise<CoolapkResponse> {
    return CoolapkApi.get('/v6/notification/checkCount');
  }

  /**
   * 通知 / 私信列表。
   * @param path /v6/notification/atMeList 等
   */
  static async fetchNotifications(path: string, page: number = 1): Promise<CoolapkResponse> {
    const sep = path.indexOf('?') >= 0 ? '&' : '?';
    return CoolapkApi.get(path + sep + 'page=' + page.toString());
  }

  /** 私信会话内容。 */
  static async fetchChat(ukey: string, page: number = 1): Promise<CoolapkResponse> {
    return CoolapkApi.get('/v6/message/chat?ukey=' + encodeURIComponent(ukey) +
      '&page=' + page.toString());
  }

  /**
   * 点赞 / 取消点赞动态。
   * @param action like / unlike
   */
  static async postLike(action: string, id: string): Promise<CoolapkResponse> {
    return CoolapkApi.post('/v6/feed/' + action + '?id=' + encodeURIComponent(id));
  }

  /**
   * 发送私信。
   *
   * 协议为 multipart/form-data：message = 正文，message_pic = 图片地址（可为空串）。
   * 注意：multipart 的 boundary 由框架生成，必须去掉手写的 Content-Type。
   */
  static async sendMessage(uid: string, text: string, pic: string): Promise<CoolapkResponse> {
    const deviceCode = getDeviceCode();
    const token = tokenFor(deviceCode);
    const cookie = buildCookieHeaderSync();
    const raw = buildHeaders(token, deviceCode, cookie);
    const headers: Record<string, string> = {};
    const keys = Object.keys(raw);
    for (const k of keys) {
      if (k !== 'Content-Type') {
        headers[k] = raw[k];
      }
    }

    // multipart POST 命中风控时退化为 query 参数重放（对齐 Android 版 buildRetry）
    const sendPath = '/v6/message/send?uid=' + encodeURIComponent(uid);
    const replay = inReplayWindowSync();
    const url = API_HOST + withProofSync(sendPath, replay);
    const form: Array<http.MultiFormData> = [];
    const msgPart: http.MultiFormData = {
      name: 'message',
      contentType: 'text/plain',
      data: text,
    };
    form.push(msgPart);
    const picPart: http.MultiFormData = {
      name: 'message_pic',
      contentType: 'text/plain',
      data: pic,
    };
    form.push(picPart);

    const req = http.createHttp();
    try {
      const res = await req.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        multiFormDataList: form,
        readTimeout: 20000,
        connectTimeout: 15000,
      });
      const rawResult = res.result;
      const body: string = typeof rawResult === 'string' ? rawResult : '';
      return await handleChallenge(makeResponse(res.responseCode, body));
    } catch (e) {
      hilog.error(DOMAIN, 'c001apk', 'sendMessage failed: %{public}s', JSON.stringify(e));
      return makeResponse(-1, '');
    } finally {
      req.destroy();
    }
  }

  /** 当前 v3 token（调试用，页面可展示前若干位确认算法生效）。 */
  static currentTokenPreview(): string {
    const token = getTokenV3(getDeviceCode());
    return token.length > 24 ? token.substring(0, 24) + '…' : token;
  }
}
