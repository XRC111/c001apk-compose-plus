/**
 * 设备标识（X-App-Device）。
 *
 * 酷安 Android 版的 xAppDevice 是：
 *   base64("$szlmId; ; ; $mac; $manufacturer; $brand; $model; $buildNumber; null")
 * 再整体反转并去掉 '='。
 *
 * HarmonyOS 拿不到 Android ID，这里用一组**固定**的机型信息生成，
 * 好处是跨启动天然稳定（同一设备码），不依赖 Preferences 也能保证
 * token / 设备识别一致。后续可在设置页允许用户覆盖。
 */
import { base64Encode } from './StandardBase64';
import { utf8ToBytes } from './Md5';

/** 默认机型信息（与 Android 版字段顺序完全一致）。 */
const DEFAULT_SZLM_ID: string = '';
const DEFAULT_MAC: string = '02:00:00:00:00:00';
const DEFAULT_MANUFACTURER: string = 'Xiaomi';
const DEFAULT_BRAND: string = 'Xiaomi';
const DEFAULT_MODEL: string = 'M2012K11AC';
const DEFAULT_BUILD_NUMBER: string = 'a1b2c3d4e5f60718';

/** 反转字符串（对应 Android 版的 StringBuilder.reverse()）。 */
function reverseString(s: string): string {
  let out = '';
  for (let i = s.length - 1; i >= 0; i--) {
    out += s.charAt(i);
  }
  return out;
}

/**
 * 生成 X-App-Device。
 * @param overrides 可覆盖字段（例如用户填了 ShuzlmID）
 */
export function generateDeviceCode(overrides?: DeviceInfoOverrides): string {
  const szlmId = overrides?.szlmId ?? DEFAULT_SZLM_ID;
  const mac = overrides?.mac ?? DEFAULT_MAC;
  const manufacturer = overrides?.manufacturer ?? DEFAULT_MANUFACTURER;
  const brand = overrides?.brand ?? DEFAULT_BRAND;
  const model = overrides?.model ?? DEFAULT_MODEL;
  const buildNumber = overrides?.buildNumber ?? DEFAULT_BUILD_NUMBER;

  const raw =
    szlmId + '; ; ; ' + mac + '; ' + manufacturer + '; ' + brand + '; ' +
      model + '; ' + buildNumber + '; null';

  const b64 = base64Encode(utf8ToBytes(raw));
  return reverseString(b64).replace(/=/g, '').replace(/[\r\n]/g, '');
}

export interface DeviceInfoOverrides {
  szlmId?: string;
  mac?: string;
  manufacturer?: string;
  brand?: string;
  model?: string;
  buildNumber?: string;
}

/** 进程内缓存的设备码（首次访问时生成）。 */
let cachedDeviceCode: string = '';

export function getDeviceCode(): string {
  if (cachedDeviceCode.length === 0) {
    cachedDeviceCode = generateDeviceCode();
  }
  return cachedDeviceCode;
}

/** 允许设置页覆盖（例如导入官方 ShuzlmID 后重新生成）。 */
export function setDeviceCode(overrides: DeviceInfoOverrides): string {
  cachedDeviceCode = generateDeviceCode(overrides);
  return cachedDeviceCode;
}
