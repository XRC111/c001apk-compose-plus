/**
 * 酷安 X-App-Token v3 / v2（HarmonyOS 原生平移）。
 *
 * 与 Android 版 TokenDeviceUtils.kt 逐位对齐，两个容易踩错的点：
 *  1. 计算 bcrypt 口令时，base64 **保留 '=' padding**（Kotlin 的 NO_WRAP 只去换行）；
 *     只有 saltSrc 和最终 token 才 replace("=")。
 *  2. bcrypt 的 salt 由标准 base64 生成，可能含 '+'；jBCrypt 遇到非字母表字符会
 *     截断解码而不是报错，Bcrypt.ets 已复刻该行为。
 */
import { md5HexUtf8, md5HexBytes, utf8ToBytes } from './Md5';
import { bcryptHash } from './Bcrypt';
import {
  asciiToBytes,
  base64Decode,
  base64Encode,
  base64EncodeRaw,
  concatBytes,
  latin1ToUtf8Bytes,
} from './StandardBase64';
import { AUTH_BLOB_TEXT } from './AuthBlob';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0xD0001;

export const APP_ID: string = 'com.coolapk.market';
export const APP_LABEL: string = 'token://com.coolapk.market/dcf01e569c1e3db93a3d0fcf191a622c';
export const VERSION_NAME: string = '16.6.4';
export const API_VERSION: string = '16';
export const VERSION_CODE: string = '2609291';
export const CHANNEL: string = 'xiaomi';
export const MODE: string = 'community';

const VERSION_CODE_NUM: number = 2609291;
const STD_B64: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

/** 把 base64 末位在标准字母表上偏移若干位（Android 版的 -5 偏移）。 */
function shiftLastB64Char(s: string, shift: number): string {
  const idx = STD_B64.indexOf(s.charAt(s.length - 1));
  if (idx < 0) {
    return s;
  }
  const ni = ((idx + shift) % 64 + 64) % 64;
  return s.substring(0, s.length - 1) + STD_B64.charAt(ni);
}

function buildTokenV3(deviceCode: string, ts: number): string {
  const idx = ((ts + VERSION_CODE_NUM) % 100) * 4 + 0x80;
  if (idx + 0x80 > AUTH_BLOB_TEXT.length) {
    throw new Error('auth blob index out of range: ' + idx.toString());
  }
  // Android: String(blob[idx..idx+128], ISO_8859_1).trim() 再 base64 解码
  const chunk = AUTH_BLOB_TEXT.substring(idx, idx + 0x80).trim();
  const segment: number[] = base64Decode(chunk);

  // plain = pkg & segment & md5(deviceCode) & ts & versionCode
  const plain: number[] = concatBytes([
    utf8ToBytes(APP_ID),
    asciiToBytes('&'),
    segment,
    asciiToBytes('&'),
    asciiToBytes(md5HexUtf8(deviceCode)),
    asciiToBytes('&'),
    asciiToBytes(ts.toString()),
    asciiToBytes('&'),
    asciiToBytes(VERSION_CODE),
  ]);

  // bcrypt 口令 = md5(base64(plain))，此处 base64 保留 padding
  const pw: string = md5HexUtf8(base64Encode(plain));

  // salt: base64(hex(ts)/md5(plain))[:22]，末位偏移 -5
  const plainMd5: string = md5HexBytes(latin1ToUtf8Bytes(plain));
  const saltSrc: string = base64EncodeRaw(asciiToBytes(ts.toString(16) + '/' + plainMd5));
  const salt22: string = shiftLastB64Char(saltSrc.substring(0, 22), -5);

  const hashed: string = bcryptHash(pw, '$2a$10$' + salt22);
  // jBCrypt 只认 $2a$；酷安要求 $2y$
  const bcryptResult: string = '$2y' + hashed.substring(3);

  return 'v3' + base64EncodeRaw(asciiToBytes(bcryptResult));
}

/**
 * 获取 v3 token。
 *
 * Android 版会从当前秒开始向后探 16 秒，以规避个别时间戳下 bcrypt salt 非法；
 * 这里保持一致。全部失败时退回 v2。
 */
export function getTokenV3(deviceCode: string): string {
  const start = Math.floor(Date.now() / 1000);
  for (let offset = 0; offset <= 15; offset++) {
    const ts = start + offset;
    try {
      return buildTokenV3(deviceCode, ts);
    } catch (e) {
      // 该秒的 salt 不可用，试下一秒（真机诊断需要知道到底抛了什么）
      hilog.warn(DOMAIN, 'c001apk', 'buildTokenV3 fail ts=%{public}d err=%{public}s',
        ts, JSON.stringify(e));
    }
  }
  hilog.error(DOMAIN, 'c001apk', 'v3 全部失败，降级 v2（服务端已不接受 v2）');
  return getTokenV2(deviceCode);
}

/**
 * v2 token（旧协议，仅作 v3 失败时的兜底）。
 *
 * 注：Android 版时间戳取的是 `millis / 1000f` 的 Float 字符串，
 * 在 1e9 量级下 Java 会输出科学计数法且有效数字只有 ~7 位。
 * 这里按「整秒 + .0」近似，可能与 Android 版不完全逐位一致，
 * 但 v2 只是兜底路径，正常请求走 v3。
 */
export function getTokenV2(deviceCode: string): string {
  const tsStr: string = Math.floor(Date.now() / 1000).toString() + '.0';
  const base64TimeStamp: string = base64EncodeRaw(asciiToBytes(tsStr));
  const md5TimeStamp: string = md5HexUtf8(tsStr);
  const md5DeviceCode: string = md5HexUtf8(deviceCode);

  const token: string = APP_LABEL + '?' + md5TimeStamp + '$' + md5DeviceCode + '&' + APP_ID;
  const base64Token: string = base64EncodeRaw(asciiToBytes(token));
  const md5Base64Token: string = md5HexUtf8(base64Token);
  const md5Token: string = md5HexUtf8(token);

  // Android: ("$2a$10$$base64TimeStamp/$md5Token".substring(0, 31)) + "u"
  const saltFull: string = '$2a$10$' + base64TimeStamp + '/' + md5Token;
  const bcryptSalt: string = saltFull.substring(0, 31) + 'u';
  const bcryptResult: string = bcryptHash(md5Base64Token, bcryptSalt);

  return 'v2' + base64EncodeRaw(asciiToBytes('$2y' + bcryptResult.substring(3)));
}

/** 通用请求头（不含登录 Cookie；登录态后续接入 Preferences 再补）。 */
export function commonHeaders(token: string): Record<string, string> {
  return {
    'User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 16; ' + VERSION_NAME + ')',
    'X-App-Token': token,
    'X-App-Version': VERSION_NAME,
    'X-App-Code': VERSION_CODE,
    'X-Api-Version': API_VERSION,
    'X-App-Channel': CHANNEL,
    'X-App-Mode': MODE,
    'X-Requested-With': 'XMLHttpRequest',
    'Accept': 'application/json',
  };
}
