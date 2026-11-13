/**
 * 本地设置持久化（HarmonyOS Preferences）。
 *
 * 只存少量关键值：ShuzlmID、设备码、Cookie 与风控凭证。
 *
 * 性能要点（真机上"一卡一卡"的根因就在这里）：
 *  - Preferences 的 get 是异步跨线程调用，put + flush 还会落盘。
 *    之前每个网络请求要读 6 次（5 个 Cookie 字段 + 重放窗口），
 *    每个响应还可能 flush 一次 SESSID，列表滚动时开销非常明显。
 *  - 现在所有值都先走内存缓存，命中即同步返回，不再触达 Preferences；
 *    写入只更新内存并标记脏，由 [flush] 落盘。
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

/** 内存缓存：key -> 值。初始化时一次性载入，之后读不再跨线程。 */
const cache: Map<string, string> = new Map<string, string>();
let cacheLoaded: boolean = false;
let dirty: boolean = false;

/** 初始化时预载的 key。 */
const PRELOAD_KEYS: string[] = [
  'uid', 'username', 'token', 'SESSID', 'validate', 'captchaId',
  'captchaField', 'replayAt', KEY_SZLM_ID, KEY_DEVICE_CODE,
];

async function doInit(context: common.UIAbilityContext): Promise<void> {
  try {
    store = await preferences.getPreferences(context, STORE_NAME);
    for (const k of PRELOAD_KEYS) {
      const v = await store.get(k, '');
      if (typeof v === 'string' && v.length > 0) {
        cache.set(k, v);
      }
    }
    cacheLoaded = true;
    hilog.info(DOMAIN, 'c001apk', 'SettingsStore ready, cached=%{public}d', cache.size);
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

/** 同步读取（内存命中），不触达磁盘。 */
export function getStringSync(key: string, defValue: string): string {
  const v = cache.get(key);
  return v === undefined ? defValue : v;
}

/** 写内存（不落盘），由 [flush] 统一提交。 */
export function setStringSync(key: string, value: string): void {
  if (value.length === 0) {
    cache.delete(key);
  } else {
    cache.set(key, value);
  }
  dirty = true;
}

/** 把脏数据落盘。 */
export async function flush(): Promise<void> {
  if (store === null || !dirty) {
    return;
  }
  dirty = false;
  try {
    const keys: string[] = Array.from(cache.keys());
    for (const k of keys) {
      const v = cache.get(k);
      if (v !== undefined) {
        await store.put(k, v);
      }
    }
    await store.flush();
  } catch (e) {
    dirty = true;
    hilog.error(DOMAIN, 'c001apk', 'flush failed: %{public}s', JSON.stringify(e));
  }
}

/** 读字符串：走内存缓存；仅在极早期未预载时回落一次真实读取。 */
export async function getString(key: string, defValue: string): Promise<string> {
  if (!cacheLoaded && store !== null) {
    try {
      const v = await store.get(key, defValue);
      if (typeof v === 'string') {
        cache.set(key, v);
        return v;
      }
      return defValue;
    } catch (e) {
      return defValue;
    }
  }
  return getStringSync(key, defValue);
}

/**
 * 写字符串。
 *
 * @param persist 是否立即落盘。高频路径（如每次响应回写 SESSID）传 false，
 *                只更新内存，由调用方择机 flush，避免每次响应都写盘。
 */
export async function putString(key: string, value: string, persist: boolean = true): Promise<void> {
  setStringSync(key, value);
  if (persist) {
    await flush();
  }
}
