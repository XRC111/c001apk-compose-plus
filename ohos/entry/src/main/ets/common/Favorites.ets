/**
 * 本地收藏（对齐 Android 版 feed_favorite Room 数据库）。
 *
 * Android 版收藏完全在本地，没有服务端接口；这里用 Preferences 存一个
 * 逗号分隔的 feedId 列表。读写都走 SettingsStore 的内存缓存，不落盘阻塞 UI。
 */
import { getStringSync, setStringSync, flush } from './SettingsStore';

const KEY_FAVORITES: string = 'favorites';

function parseIds(raw: string): string[] {
  if (raw.length === 0) {
    return [];
  }
  return raw.split(',').filter((s: string) => s.length > 0);
}

export function isFavorited(feedId: string): boolean {
  const ids = parseIds(getStringSync(KEY_FAVORITES, ''));
  return ids.indexOf(feedId) >= 0;
}

export function allFavorites(): string[] {
  return parseIds(getStringSync(KEY_FAVORITES, ''));
}

/** 切换收藏状态，返回切换后是否已收藏。 */
export function toggleFavorite(feedId: string): boolean {
  const ids = parseIds(getStringSync(KEY_FAVORITES, ''));
  const idx = ids.indexOf(feedId);
  let nowFav: boolean;
  if (idx >= 0) {
    ids.splice(idx, 1);
    nowFav = false;
  } else {
    ids.push(feedId);
    nowFav = true;
  }
  setStringSync(KEY_FAVORITES, ids.join(','));
  flush();
  return nowFav;
}
