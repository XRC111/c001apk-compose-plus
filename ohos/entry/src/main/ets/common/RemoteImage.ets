/**
 * 带自定义请求头的网络图片加载。
 *
 * 为什么需要它：酷安图片服务（image.coolapk.com / avatar.coolapk.com）
 * **要求同时带 User-Agent 与 Referer**，缺任一就返回 `567 Unknown Status`。
 * 实测（本机直连，2026-11）：
 *   UA + Referer → HTTP 200 image/jpeg 128611 字节
 *   只有 UA      → 567
 *   只有 Referer → 567
 * 而 ArkUI 的 Image() 组件不支持自定义请求头，所以必须自己下载：
 *   1. http.request 带 UA/Referer 取回 ArrayBuffer
 *   2. image.createImageSource 解码成 PixelMap
 *   3. 交给 Image(pixelMap) 渲染
 * 解码结果按 URL 缓存，避免列表滚动时重复下载与解码。
 */
import { http } from '@kit.NetworkKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { httpsUrl } from './Feed';

const DOMAIN: number = 0xD0001;

const UA: string = 'Dalvik/2.1.0 (Linux; U; Android 16; M2012K11AC a1b2c3d4e5f60718) ' +
  '(#Build; Xiaomi; M2012K11AC; a1b2c3d4e5f60718; 16) +CoolMarket/16.6.4-2609291-community';
const REFERER: string = 'https://www.coolapk.com/';

/** 解码后的图片缓存（URL -> PixelMap）。上限约 80 张，防止内存膨胀。 */
const cache: Map<string, image.PixelMap> = new Map<string, image.PixelMap>();
const MAX_CACHE: number = 80;

/** 在途请求合并：同一 URL 并发只下载一次。 */
const inflight: Map<string, Promise<image.PixelMap | null>> =
  new Map<string, Promise<image.PixelMap | null>>();

function putCache(url: string, pm: image.PixelMap): void {
  if (cache.size >= MAX_CACHE) {
    const first: IteratorResult<string, undefined> = cache.keys().next();
    if (first.done !== true) {
      cache.delete(first.value);
    }
  }
  cache.set(url, pm);
}

/** 取已缓存的 PixelMap（同步，供 build 里直接用）。 */
export function getCachedImage(url: string): image.PixelMap | undefined {
  return cache.get(url);
}

/**
 * 下载并解码图片。
 * @param rawUrl 原始 URL（内部会自动把 http 升到 https）
 */
export async function loadImage(rawUrl: string): Promise<image.PixelMap | null> {
  if (rawUrl.length === 0) {
    return null;
  }
  const url: string = httpsUrl(rawUrl);
  const hit: image.PixelMap | undefined = cache.get(url);
  if (hit !== undefined) {
    return hit;
  }
  const running: Promise<image.PixelMap | null> | undefined = inflight.get(url);
  if (running !== undefined) {
    return running;
  }
  const task: Promise<image.PixelMap | null> = doLoad(url);
  inflight.set(url, task);
  try {
    return await task;
  } finally {
    inflight.delete(url);
  }
}

async function doLoad(url: string): Promise<image.PixelMap | null> {
  const req: http.HttpRequest = http.createHttp();
  try {
    const headers: Record<string, string> = {
      'User-Agent': UA,
      'Referer': REFERER,
    };
    const res: http.HttpResponse = await req.request(url, {
      method: http.RequestMethod.GET,
      header: headers,
      expectDataType: http.HttpDataType.ARRAY_BUFFER,
      readTimeout: 20000,
      connectTimeout: 15000,
    });
    if (res.responseCode !== 200) {
      hilog.warn(DOMAIN, 'c001apk', 'image http %{public}d', res.responseCode);
      return null;
    }
    const data: Object = res.result;
    if (!(data instanceof ArrayBuffer)) {
      hilog.warn(DOMAIN, 'c001apk', 'image not ArrayBuffer');
      return null;
    }
    const buf: ArrayBuffer = data as ArrayBuffer;
    const src: image.ImageSource = image.createImageSource(buf);
    // ArkTS 要求 desiredSize 显式声明为 image.Size，不能用裸对象字面量
    const size: image.Size = { width: 720, height: 720 };
    const opt: image.InitializationOptions = { desiredSize: size };
    const pm: image.PixelMap = await src.createPixelMap(opt);
    src.release();
    putCache(url, pm);
    return pm;
  } catch (e) {
    hilog.error(DOMAIN, 'c001apk', 'image load fail %{public}s', JSON.stringify(e));
    return null;
  } finally {
    req.destroy();
  }
}
