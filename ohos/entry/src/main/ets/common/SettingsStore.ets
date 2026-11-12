/**
 * 本地设置持久化（HarmonyOS Preferences）。
 *
 * 只存少量关键值：ShuzlmID、设备码。首次使用时由页面调用 [initSettings]，
 * 内部对初始化做了去重，重复调用安全。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const STORE_NAME: string = 'c001apk_settings';

/** 设置项 key。 */
export const KEY_SZLM_ID: string = 'szlmId';
export const KEY_DEVICE_CODE: string = 'xAppDevice';

let store: preferences.Preferences | null = null;
let initPromise: Promise<void> | null = null;

async function doInit(context: common.UIAbilityContext): Promise<void> {
  try {
    store = await preferences.getPreferences(context, STORE_NAME);
    hilog.info(DOMAIN, 'c001apk', 'SettingsStore ready');
  } catch (e) {
    hilog.error(DOMAIN, 'c001apk', 'SettingsStore init failed: %{public}s', JSON.stringify(e));
    store = null;
  }
}

/** 初始化（幂等）。 */
export function initSettings(context: common.UIAbilityContext): Promise<void> {
  if (initPromise === null) {
    initPromise = doInit(context);
  }
  return initPromise;
}

/** 是否可用（初始化失败时为 false，页面据此提示）。 */
export function isSettingsReady(): boolean {
  return store !== null;
}

/** 读字符串，失败或不存在时返回默认值。 */
export async function getString(key: string, defValue: string): Promise<string> {
  if (store === null) {
    return defValue;
  }
  try {
    const v = await store.get(key, defValue);
    return typeof v === 'string' ? v : defValue;
  } catch (e) {
    hilog.error(DOMAIN, 'c001apk', 'get %{public}s failed: %{public}s', key, JSON.stringify(e));
    return defValue;
  }
}

/** 写字符串并落盘。 */
export async function putString(key: string, value: string): Promise<void> {
  if (store === null) {
    return;
  }
  try {
    await store.put(key, value);
    await store.flush();
  } catch (e) {
    hilog.error(DOMAIN, 'c001apk', 'put %{public}s failed: %{public}s', key, JSON.stringify(e));
  }
}
