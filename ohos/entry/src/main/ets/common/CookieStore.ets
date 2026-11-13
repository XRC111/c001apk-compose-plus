/**
 * 登录态与风控凭证的本地存储。
 *
 * 与 Android 版 Cookie 组成保持一致：
 *   uid / username / token  （登录态，三者同时存在才算已登录）
 *   SESSID                  （服务端下发，可能已含 "SESSID=" 前缀）
 *   validate                （易盾验证凭证，原样作为 Cookie 值）
 */
import { getString, getStringSync, putString, setStringSync } from './SettingsStore';

export const KEY_UID: string = 'uid';
export const KEY_USERNAME: string = 'username';
export const KEY_TOKEN: string = 'token';
export const KEY_SESSID: string = 'SESSID';
export const KEY_VALIDATE: string = 'validate';
export const KEY_CAPTCHA_ID: string = 'captchaId';
export const KEY_CAPTCHA_FIELD: string = 'captchaField';

/**
 * 拼出 Cookie 头；无任何凭证时返回空串。
 *
 * 性能：全部走内存缓存同步拼接，不做任何异步/磁盘读取。
 * 之前每次请求都会 await 5 次 Preferences，列表滚动时累积成明显卡顿。
 */
export function buildCookieHeaderSync(): string {
  const parts: string[] = [];

  const uid = getStringSync(KEY_UID, '');
  const username = getStringSync(KEY_USERNAME, '');
  const token = getStringSync(KEY_TOKEN, '');
  if (uid.length > 0 && token.length > 0) {
    parts.push('uid=' + uid);
    parts.push('username=' + username);
    parts.push('token=' + token);
  }

  const sessid = getStringSync(KEY_SESSID, '');
  if (sessid.length > 0) {
    parts.push(sessid);
  }

  const validate = getStringSync(KEY_VALIDATE, '');
  if (validate.length > 0) {
    parts.push('validate=' + validate);
  }

  return parts.join('; ');
}


/** 是否已登录。 */
/** 是否已登录（同步，走内存缓存）。 */
export function isLoggedInSync(): boolean {
  const uid = getStringSync(KEY_UID, '');
  const token = getStringSync(KEY_TOKEN, '');
  return uid.length > 0 && token.length > 0;
}

/** 是否已登录。 */
export async function isLoggedIn(): Promise<boolean> {
  return isLoggedInSync();
}

/** 保存登录态。 */
export async function saveLogin(uid: string, username: string, token: string): Promise<void> {
  await putString(KEY_UID, uid);
  await putString(KEY_USERNAME, username);
  await putString(KEY_TOKEN, token);
}

/** 清除登录态（退出登录）。 */
export async function clearLogin(): Promise<void> {
  await putString(KEY_UID, '');
  await putString(KEY_USERNAME, '');
  await putString(KEY_TOKEN, '');
}

/**
 * 保存风控验证凭证。
 *
 * 注意：不能直接存易盾回调的裸 validate。Android 版 CaptchaChallenge.proof()
 * 要求写成 "NEC:<captchaId前8位>:<validate>"，服务端才认。
 */
export async function saveValidate(validate: string, captchaId: string): Promise<void> {
  const proof = 'NEC:' + captchaId.substring(0, 8) + ':' + validate;
  await putString(KEY_VALIDATE, proof);
  await putString(KEY_CAPTCHA_ID, captchaId);
}

/** 清除失效的验证凭证。 */
export async function clearValidate(): Promise<void> {
  await putString(KEY_VALIDATE, '');
}

/**
 * 保存 SESSID。
 *
 * 高频路径：几乎每个响应都可能带回新的 SESSID。这里只更新内存不落盘，
 * 由 [flush] 择机提交，避免每次响应都写磁盘造成卡顿。
 */
export async function saveSessid(sessid: string): Promise<void> {
  await putString(KEY_SESSID, sessid, false);
}

/** 当前登录用户名（未登录返回空串）。 */
export async function currentUsername(): Promise<string> {
  return await getString(KEY_USERNAME, '');
}

/** 保存风控挑战的字段名，供重放时拼 query。 */
export async function saveCaptchaField(field: string): Promise<void> {
  await putString(KEY_CAPTCHA_FIELD, field);
}


const DEFAULT_CAPTCHA_FIELD: string = '_v2_post_token';
const KEY_REPLAY_AT: string = 'replayAt';

/**
 * 验证成功后标记一个「重放窗口」。
 *
 * 为什么用时间窗口而不是一次性标记：验证返回后多个页面会同时重新拉取
 * （首页 + 详情页 + 消息页），若只让第一个请求消费标记，其余请求拿不到凭证
 * 会立刻再次命中风控，形成「验证→再被拦」的死循环。
 */
export async function markReplayPending(): Promise<void> {
  await putString(KEY_REPLAY_AT, Date.now().toString());
}

/** 是否处于重放窗口内（默认 8 秒），同步走内存缓存。 */
export function inReplayWindowSync(): boolean {
  const v = getStringSync(KEY_REPLAY_AT, '');
  if (v.length === 0) {
    return false;
  }
  const at = parseInt(v, 10);
  if (isNaN(at)) {
    return false;
  }
  const age = Date.now() - at;
  if (age < 0 || age > 8000) {
    setStringSync(KEY_REPLAY_AT, '');
    return false;
  }
  return true;
}

/** 是否有生效中的 NEC 凭证（用于同步版 withProof）。 */
export function currentProofSync(): string {
  return getStringSync(KEY_VALIDATE, '');
}

/** 当前挑战字段名（同步）。 */
export function currentFieldSync(): string {
  return getStringSync(KEY_CAPTCHA_FIELD, DEFAULT_CAPTCHA_FIELD);
}


/**
 * 同步版重放凭证拼接。
 * @param path 原请求路径
 * @param replay 是否处于重放窗口
 */
export function withProofSync(path: string, replay: boolean): string {
  if (!replay) {
    return path;
  }
  const proof = currentProofSync();
  if (proof.length === 0) {
    return path;
  }
  const field = currentFieldSync();
  if (field.length === 0) {
    return path;
  }
  const sep = path.indexOf('?') >= 0 ? '&' : '?';
  return path + sep + encodeURIComponent(field) + '=' + encodeURIComponent(proof);
}
