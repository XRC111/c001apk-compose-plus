/**
 * 首页信息流的数据模型与解析。
 *
 * 只取列表展示需要的少数字段；酷安 `indexV8` 的字段很多，
 * 全量建模收益不大，且 ArkTS 对未知字段的兼容性差。
 */

export interface FeedItem {
  id?: string;
  title?: string;
  message?: string;
  username?: string;
  entityType?: string;
  turl?: string;
}

export interface FeedEnvelope {
  data?: FeedItem[];
}

export interface ParsedFeed {
  items: FeedItem[];
  error: string;
}

/** 解析首页响应；失败时返回空列表并附带错误信息，不抛异常。 */
export function parseFeed(body: string): ParsedFeed {
  const empty: ParsedFeed = { items: [], error: '' };
  if (body.length === 0) {
    empty.error = '响应为空';
    return empty;
  }
  try {
    const env: FeedEnvelope = JSON.parse(body) as FeedEnvelope;
    const data = env.data;
    if (data === undefined || data === null) {
      empty.error = '响应中没有 data 字段';
      return empty;
    }
    const result: ParsedFeed = { items: data, error: '' };
    return result;
  } catch (e) {
    empty.error = 'JSON 解析失败';
    return empty;
  }
}

/** 列表项展示用的一行摘要（标题优先，其次正文）。 */
export function feedSummary(item: FeedItem): string {
  const title = item.title;
  if (title !== undefined && title.length > 0) {
    return title;
  }
  const msg = item.message;
  if (msg !== undefined && msg.length > 0) {
    return msg;
  }
  return '(无内容)';
}

/** 列表项角标：返回实体类型的中文短标签。 */
export function feedTypeLabel(item: FeedItem): string {
  const t = item.entityType;
  if (t === undefined) {
    return '动态';
  }
  if (t === 'feed') {
    return '动态';
  }
  if (t === 'product') {
    return '应用';
  }
  if (t === 'topic') {
    return '话题';
  }
  if (t === 'article') {
    return '文章';
  }
  return t;
}
