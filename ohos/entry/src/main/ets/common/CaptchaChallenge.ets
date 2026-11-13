/**
 * 酷安新版风控挑战解析（对齐 Android 版 CaptchaChallenge.kt）。
 *
 * 服务端返回示例：
 * {"status":403,"message":"当前访问需要验证码",
 *  "messageStatus":"err_request_captcha_v2",
 *  "messageExtra":{"captchaId":"...","captchaField":"_v2_post_token"}}
 *
 * 关键坑（Android 版已踩过）：
 *  - captchaId 常在 messageExtra / extra 里，且该字段还可能是**嵌套的 JSON 字符串**
 *  - 取不到时要用 DEFAULT_ID，而不是空串（空串会导致易盾不渲染）
 *  - validate 凭证不是裸串，而是 "NEC:<captchaId前8位>:<validate>"
 */
export const CAPTCHA_STATUS: string = 'err_request_captcha_v2';
export const DEFAULT_CAPTCHA_ID: string = '414e5c9b866a03db03f860a1a9101672';
export const DEFAULT_CAPTCHA_FIELD: string = '_v2_post_token';

export interface CaptchaChallenge {
  captchaId: string;
  field: string;
}

interface ExtraLike {
  captchaId?: string;
  captchaField?: string;
}

interface RootLike {
  messageStatus?: string;
  messageExtra?: ExtraLike | string;
  extra?: ExtraLike | string;
  captchaId?: string;
  captchaField?: string;
}

/** 从风控响应体解析挑战；非风控响应返回 null。 */
export function parseChallenge(body: string): CaptchaChallenge | null {
  if (body.length === 0 || body.indexOf(CAPTCHA_STATUS) < 0) {
    return null;
  }
  let root: RootLike;
  try {
    root = JSON.parse(body) as RootLike;
  } catch (e) {
    return null;
  }
  if (root.messageStatus !== CAPTCHA_STATUS) {
    return null;
  }

  // messageExtra / extra 既可能是对象，也可能是 JSON 字符串
  let extra: ExtraLike | null = null;
  const node = root.messageExtra !== undefined ? root.messageExtra : root.extra;
  if (typeof node === 'string') {
    try {
      const parsed = JSON.parse(node) as ExtraLike;
      extra = parsed;
    } catch (e) {
      extra = null;
    }
  } else if (node !== undefined && node !== null) {
    extra = node;
  }
  const source: ExtraLike = extra !== null ? extra : root;

  const rawId = source.captchaId;
  const captchaId = rawId !== undefined && /^[a-zA-Z0-9]{16,64}$/.test(rawId)
    ? rawId
    : DEFAULT_CAPTCHA_ID;

  const rawField = source.captchaField;
  let field = DEFAULT_CAPTCHA_FIELD;
  if (rawField !== undefined) {
    const trimmed = rawField.trim();
    if (trimmed.length === 0) {
      field = '';
    } else if (/^_[a-zA-Z0-9_]{1,63}$/.test(trimmed)) {
      field = trimmed;
    }
  }

  const ch: CaptchaChallenge = { captchaId: captchaId, field: field };
  return ch;
}

/** 易盾回调的 validate → 服务端要求的 NEC 凭证串。 */
export function makeProof(captchaId: string, validate: string): string {
  return 'NEC:' + captchaId.substring(0, 8) + ':' + validate;
}
