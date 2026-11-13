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
  picArr?: string[];
  uid?: string;
  userAvatar?: string;
  likenum?: string;
  commentnum?: string;
  replynum?: string;
  dateline?: number;
  apkname?: string;
  apkversionname?: string;
  apksize?: string;
  downCount?: string;
  downnum?: string;
  ukey?: string;
  isnew?: number;
  // ---- 以下为解析时预计算的派生字段（避免 build() 内每帧重算）----
  pics?: string[];
  avatar?: string;
  summary?: string;
  typeLabel?: string;
  timeText?: string;
  initial?: string;
  usernameText?: string;
  likeText?: string;
  commentText?: string;
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

export interface UserAction {
  like?: number;
  favorite?: number;
  follow?: number;
}

export interface FeedDetailData {
  id?: string;
  title?: string;
  message?: string;
  username?: string;
  picArr?: string[];
  likes?: string;
  dateline?: number;
  uid?: string;
  userAction?: UserAction;
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
    for (const it of data) {
      enrichFeed(it);
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

/** 应用详情的数据模型（字段名与酷安 JSON 一致）。 */
export interface AppDetailData {
  apkname?: string;
  title?: string;
  apkversionname?: string;
  apksize?: string;
  downCount?: string;
  downnum?: string;
  commentnum?: string;
  commentNum?: string;
  changelog?: string;
  message?: string;
  intro?: string;
  packageName?: string;
  pic?: string;
  tpic?: string;
  lastupdate?: number;
  entityType?: string;
}

export interface AppDetailEnvelope {
  data?: AppDetailData;
}

export interface ParsedAppDetail {
  app: AppDetailData | null;
  error: string;
}

/** 解析应用详情响应。 */
export function parseAppDetail(body: string): ParsedAppDetail {
  const empty: ParsedAppDetail = { app: null, error: '' };
  if (body.length === 0) {
    empty.error = '响应为空';
    return empty;
  }
  try {
    const env: AppDetailEnvelope = JSON.parse(body) as AppDetailEnvelope;
    const data = env.data;
    if (data === undefined || data === null) {
      empty.error = '响应中没有 data 字段';
      return empty;
    }
    const result: ParsedAppDetail = { app: data, error: '' };
    return result;
  } catch (e) {
    empty.error = 'JSON 解析失败';
    return empty;
  }
}

/** 应用名：优先 apkname，其次 title。 */
export function appName(d: AppDetailData): string {
  const a = d.apkname;
  if (a !== undefined && a.length > 0) {
    return a;
  }
  const t = d.title;
  if (t !== undefined && t.length > 0) {
    return t;
  }
  return '(未知应用)';
}

/** 应用图标。 */
export function appIcon(d: AppDetailData): string {
  const p = d.pic;
  if (p !== undefined && p.length > 0) {
    return p;
  }
  const t = d.tpic;
  if (t !== undefined && t.length > 0) {
    return t;
  }
  return '';
}

let pendingAppId: string = '';

export function setPendingAppId(id: string): void {
  pendingAppId = id;
}

export function getPendingAppId(): string {
  return pendingAppId;
}

/** 用户主页数据模型。 */
export interface UserProfileData {
  uid?: string;
  username?: string;
  bio?: string;
  level?: string;
  fans?: string;
  follow?: string;
  experience?: string;
  userAvatar?: string;
  pic?: string;
  regdate?: number;
}

export interface UserProfileEnvelope {
  data?: UserProfileData;
}

export interface ParsedProfile {
  profile: UserProfileData | null;
  error: string;
}

/** 解析用户主页响应。 */
export function parseProfile(body: string): ParsedProfile {
  const empty: ParsedProfile = { profile: null, error: '' };
  if (body.length === 0) {
    empty.error = '响应为空';
    return empty;
  }
  try {
    const env: UserProfileEnvelope = JSON.parse(body) as UserProfileEnvelope;
    const data = env.data;
    if (data === undefined || data === null) {
      empty.error = '响应中没有 data 字段';
      return empty;
    }
    const result: ParsedProfile = { profile: data, error: '' };
    return result;
  } catch (e) {
    empty.error = 'JSON 解析失败';
    return empty;
  }
}

/** 用户头像。 */
export function userAvatar(d: UserProfileData): string {
  const a = d.userAvatar;
  if (a !== undefined && a.length > 0) {
    return a;
  }
  const p = d.pic;
  if (p !== undefined && p.length > 0) {
    return p;
  }
  return '';
}

let pendingUid: string = '';

export function setPendingUid(uid: string): void {
  pendingUid = uid;
}

export function getPendingUid(): string {
  return pendingUid;
}

/** 取信息流的图片列表：优先 picArr，其次单张 pic。最多 9 张。 */
export function feedPics(item: FeedItem): string[] {
  const arr = item.picArr;
  if (arr !== undefined && arr !== null && arr.length > 0) {
    return arr.length > 9 ? arr.slice(0, 9) : arr;
  }
  const one = item.pic;
  if (one !== undefined && one.length > 0) {
    const single: string[] = [one];
    return single;
  }
  const none: string[] = [];
  return none;
}

/** 卡片头像。 */
export function feedAvatar(item: FeedItem): string {
  const a = item.userAvatar;
  if (a !== undefined && a.length > 0) {
    return a;
  }
  return '';
}

/**
 * 预计算卡片渲染需要的派生字段。
 *
 * 为什么要在解析时算：这些值原本写在 build() 里（如 feedPics(item) 每个卡片
 * 要调 6~8 次），ArkUI 每次重绘都会重新执行，长列表滚动时累积成明显卡顿。
 * 统一在数据进入列表前算一次，build() 里只做属性读取。
 */
export function enrichFeed(item: FeedItem): FeedItem {
  item.pics = feedPics(item);
  item.avatar = feedAvatar(item);
  item.summary = feedSummary(item);
  item.typeLabel = feedTypeLabel(item);
  item.timeText = timeAgo(item.dateline);
  const u = item.username;
  item.usernameText = u !== undefined && u.length > 0 ? u : '匿名用户';
  item.initial = item.usernameText.length > 0 ? item.usernameText.substring(0, 1) : '?';
  const lk = item.likenum;
  item.likeText = lk !== undefined && lk.length > 0 ? lk : '赞';
  const cm = item.commentnum;
  item.commentText = cm !== undefined && cm.length > 0 ? cm : '评论';
  return item;
}

/** 正文分段：0=普通 1=@用户 2=#话题# 3=链接。 */
export interface RichSeg {
  text: string;
  kind: number;
}

/**
 * 把酷安正文切成普通文本 / @用户 / #话题# / 链接 四类片段，
 * 供 Text + Span 分段着色（用语义色，兼容深色模式）。
 */
export function richSegments(text: string): RichSeg[] {
  const out: RichSeg[] = [];
  if (text.length === 0) {
    return out;
  }
  const re = /(https?:\/\/[^\s]+)|(@[A-Za-z0-9_\u4e00-\u9fa5-]{1,24})|(#([^#\s]{1,30})#)/g;
  let last = 0;
  let m: RegExpExecArray | null = re.exec(text);
  while (m !== null) {
    if (m.index > last) {
      const plain: RichSeg = { text: text.substring(last, m.index), kind: 0 };
      out.push(plain);
    }
    const hit = m[0];
    let kind = 0;
    if (hit.startsWith('http')) {
      kind = 3;
    } else if (hit.startsWith('@')) {
      kind = 1;
    } else {
      kind = 2;
    }
    const seg: RichSeg = { text: hit, kind: kind };
    out.push(seg);
    last = m.index + hit.length;
    m = re.exec(text);
  }
  if (last < text.length) {
    const tail: RichSeg = { text: text.substring(last), kind: 0 };
    out.push(tail);
  }
  return out;
}

/** 私信会话传参（模块级，避免 router 参数的类型转换问题）。 */
let pendingChatUkey: string = '';
let pendingChatName: string = '';

export function setPendingChat(ukey: string, name: string): void {
  pendingChatUkey = ukey;
  pendingChatName = name;
}

export function getPendingChatUkey(): string {
  return pendingChatUkey;
}

export function getPendingChatName(): string {
  return pendingChatName;
}

/**
 * 卡片图片列表（读预计算结果，build() 里可安全高频调用）。
 * 未经过 enrichFeed 的项回落到原始字段。
 */
export function picsOf(item: FeedItem): string[] {
  const p = item.pics;
  if (p !== undefined) {
    return p;
  }
  return feedPics(item);
}
