/**
 * 标准 base64（RFC 4648）编解码，纯 ArkTS 实现。
 *
 * 与 bcrypt 的专用字母表不同：这里用 `+/` 结尾的标准表。
 * 酷安 v3 token 的中间量（saltSrc、最终 token）用的是标准 base64 再去掉 '='，
 * 而计算 bcrypt 口令时用的 base64 **保留 padding**——两者必须区分。
 */

const STD_CHARS: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

/** 编码为标准 base64（保留 '=' padding）。 */
export function base64Encode(bytes: number[]): string {
  let out = '';
  let i = 0;
  const len = bytes.length;
  while (i + 2 < len) {
    const b0 = bytes[i] & 0xff;
    const b1 = bytes[i + 1] & 0xff;
    const b2 = bytes[i + 2] & 0xff;
    out += STD_CHARS.charAt(b0 >> 2);
    out += STD_CHARS.charAt(((b0 & 0x03) << 4) | (b1 >> 4));
    out += STD_CHARS.charAt(((b1 & 0x0f) << 2) | (b2 >> 6));
    out += STD_CHARS.charAt(b2 & 0x3f);
    i += 3;
  }
  const rest = len - i;
  if (rest === 1) {
    const b0 = bytes[i] & 0xff;
    out += STD_CHARS.charAt(b0 >> 2);
    out += STD_CHARS.charAt((b0 & 0x03) << 4);
    out += '==';
  } else if (rest === 2) {
    const b0 = bytes[i] & 0xff;
    const b1 = bytes[i + 1] & 0xff;
    out += STD_CHARS.charAt(b0 >> 2);
    out += STD_CHARS.charAt(((b0 & 0x03) << 4) | (b1 >> 4));
    out += STD_CHARS.charAt((b1 & 0x0f) << 2);
    out += '=';
  }
  return out;
}

/** 编码后去掉 '='（对应 Kotlin 的 `.replace("=", "")`）。 */
export function base64EncodeRaw(bytes: number[]): string {
  return base64Encode(bytes).replace(/=/g, '');
}

/**
 * 标准 base64 解码，容忍空白与缺失的 padding（对应 android.util.Base64.DEFAULT 的宽容行为）。
 */
export function base64Decode(src: string): number[] {
  const out: number[] = [];
  let buffer = 0;
  let bits = 0;
  for (let i = 0; i < src.length; i++) {
    const ch = src.charAt(i);
    if (ch === '=') {
      break;
    }
    const v = STD_CHARS.indexOf(ch);
    if (v < 0) {
      // 跳过空白等非字母表字符
      continue;
    }
    buffer = (buffer << 6) | v;
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      out.push((buffer >> bits) & 0xff);
    }
  }
  return out;
}

/** 把字符串按 ASCII 转字节（用于 hex / 数字等纯 ASCII 中间量）。 */
export function asciiToBytes(s: string): number[] {
  const out: number[] = [];
  for (let i = 0; i < s.length; i++) {
    out.push(s.charCodeAt(i) & 0xff);
  }
  return out;
}

/**
 * 模拟 Java `new String(bytes, ISO_8859_1).getBytes(UTF_8)`：
 * 每个字节先映射成 U+00XX 字符，再按 UTF-8 重新编码（>0x7F 的字节会膨胀成 2 字节）。
 * Android 版 v3 对 plain 取 MD5 时正是这个语义。
 */
export function latin1ToUtf8Bytes(bytes: number[]): number[] {
  const out: number[] = [];
  for (const b of bytes) {
    const ch = b & 0xff;
    if (ch < 0x80) {
      out.push(ch);
    } else if (ch < 0x800) {
      out.push(0xc0 | (ch >> 6));
      out.push(0x80 | (ch & 0x3f));
    } else {
      out.push(0xe0 | (ch >> 12));
      out.push(0x80 | ((ch >> 6) & 0x3f));
      out.push(0x80 | (ch & 0x3f));
    }
  }
  return out;
}

/** 拼接多个字节数组。 */
export function concatBytes(parts: number[][]): number[] {
  const out: number[] = [];
  for (const p of parts) {
    for (const b of p) {
      out.push(b & 0xff);
    }
  }
  return out;
}
