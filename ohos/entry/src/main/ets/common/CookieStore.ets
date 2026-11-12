/**
 * 登录态与风控凭证的本地存储。
 *
 * 与 Android 版 Cookie 组成保持一致：
 *   uid / username / token  （登录态，三者同时存在才算已登录）
 *   SESSID                  （服务端下发，可能已含 "SESSID=" 前缀）
 *   validate                （易盾验证凭证，原样作为 Cookie 值）
 */
import { getString, putString } from './SettingsStore';

export const KEY_UID: string = 'uid';
export const KEY_USERNAME: string = 'username';
export const KEY_TOKEN: string = 'token';
export const KEY_SESSID: string = 'SESSID';
export const KEY_VALIDATE: string = 'validate';

/** 拼出 Cookie 头；无任何凭证时返回空串。 */
export async function buildCookieHeader(): Promise<string> {
  const parts: string[] = [];

  const uid = await getString(KEY_UID, '');
  const username = await getString(KEY_USERNAME, '');
  const token = await getString(KEY_TOKEN, '');
  if (uid.length > 0 && token.length > 0) {
    parts.push('uid=' + uid);
    parts.push('username=' + username);
    parts.push('token=' + token);
  }

  const sessid = await getString(KEY_SESSID, '');
  if (sessid.length > 0) {
    parts.push(sessid);
  }

  const validate = await getString(KEY_VALIDATE, '');
  if (validate.length > 0) {
    parts.push('validate=' + validate);
  }

  return parts.join('; ');
}

/** 是否已登录。 */
export async function isLoggedIn(): Promise<boolean> {
  const uid = await getString(KEY_UID, '');
  const token = await getString(KEY_TOKEN, '');
  return uid.length > 0 && token.length > 0;
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

/** 保存风控验证凭证。 */
export async function saveValidate(validate: string): Promise<void> {
  await putString(KEY_VALIDATE, validate);
}

/** 保存 SESSID。 */
export async function saveSessid(sessid: string): Promise<void> {
  await putString(KEY_SESSID, sessid);
}

/** 当前登录用户名（未登录返回空串）。 */
export async function currentUsername(): Promise<string> {
  return await getString(KEY_USERNAME, '');
}
