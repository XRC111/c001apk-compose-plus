/**
 * 首页信息流与详情的数据模型与解析。
 *
 * 只取展示需要的字段；酷安返回的字段很多，全量建模收益不大，
 * 且 ArkTS 对未知字段兼容性差，故一律按「可选字段」处理。
 */

export interface FeedItem {
  id?: string;
  title?: string;
  message?: string;
  username?: string;
  entityType?: string;
  turl?: string;
  pic?: string;
}

export interface FeedEnvelope {
  data?: FeedItem[];
}

export interface ParsedFeed {
  items: FeedItem[];
  error: string;
}

/** 详情页传入参数。 */
export interface FeedDetailParams {
  id?: string;
}

export interface FeedDetailData {
  id?: string;
  title?: string;
  message?: string;
  username?: string;
  picArr?: string[];
  likes?: string;
  dateline?: number;
}

export interface FeedDetailEnvelope {
  data?: FeedDetailData;
}

export interface ReplyItem {
  id?: string;
  username?: string;
  message?: string;
  dateline?: number;
  likenum?: string;
}

export interface ReplyEnvelope {
  data?: ReplyItem[];
}

export interface ParsedDetail {
  detail: FeedDetailData | null;
  error: string;
}

export interface ParsedReplies {
  replies: ReplyItem[];
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

/** 解析详情响应。 */
export function parseDetail(body: string): ParsedDetail {
  const empty: ParsedDetail = { detail: null, error: '' };
  if (body.length === 0) {
    empty.error = '响应为空';
    return empty;
  }
  try {
    const env: FeedDetailEnvelope = JSON.parse(body) as FeedDetailEnvelope;
    const data = env.data;
    if (data === undefined || data === null) {
      empty.error = '响应中没有 data 字段';
      return empty;
    }
    const result: ParsedDetail = { detail: data, error: '' };
    return result;
  } catch (e) {
    empty.error = 'JSON 解析失败';
    return empty;
  }
}

/** 解析评论列表响应。 */
export function parseReplies(body: string): ParsedReplies {
  const empty: ParsedReplies = { replies: [], error: '' };
  if (body.length === 0) {
    empty.error = '响应为空';
    return empty;
  }
  try {
    const env: ReplyEnvelope = JSON.parse(body) as ReplyEnvelope;
    const data = env.data;
    if (data === undefined || data === null) {
      empty.error = '响应中没有 data 字段';
      return empty;
    }
    const result: ParsedReplies = { replies: data, error: '' };
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

/** 取可选字符串，缺省返回空串（ArkTS 里避免到处写 ?? ）。 */
export function str(v: string | undefined): string {
  return v !== undefined ? v : '';
}

/** 时间戳转「x 分钟前 / x 小时前 / x 天前」。 */
export function timeAgo(dateline: number | undefined): string {
  if (dateline === undefined || dateline <= 0) {
    return '';
  }
  const now = Math.floor(Date.now() / 1000);
  const diff = now - dateline;
  if (diff < 60) {
    return '刚刚';
  }
  if (diff < 3600) {
    return `${Math.floor(diff / 60)} 分钟前`;
  }
  if (diff < 86400) {
    return `${Math.floor(diff / 3600)} 小时前`;
  }
  if (diff < 86400 * 30) {
    return `${Math.floor(diff / 86400)} 天前`;
  }
  return `${Math.floor(diff / 86400 / 30)} 个月前`;
}

/**
 * 页面间传参：用模块级变量而非 router.getParams()。
 * router.getParams() 返回 Object，在 ArkTS 里转成接口类型容易触发类型检查告警。
 */
let pendingDetailId: string = '';

export function setPendingDetailId(id: string): void {
  pendingDetailId = id;
}

export function getPendingDetailId(): string {
  return pendingDetailId;
}
