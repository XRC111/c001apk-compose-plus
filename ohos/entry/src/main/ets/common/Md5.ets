/**
 * 纯 ArkTS MD5（RFC 1321），无系统 API 依赖。
 *
 * 为了能本地对拍验证，刻意不用 @kit.CryptoArchitectureKit：
 * 该 kit 的 updateSync/digestSync 会引入 API 版本与签名的不确定性，
 * 而 MD5 本身很短，纯实现反而更可控、可被 Node 直接执行验证。
 */

/** 每轮的循环左移位数。 */
const SHIFT: number[] = [
  7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
  5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
  4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
  6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
];

/** K[i] = floor(abs(sin(i+1)) * 2^32)，按标准定义运行时计算，避免 64 个魔数。 */
const K: number[] = (() => {
  const k: number[] = [];
  for (let i = 0; i < 64; i++) {
    k.push(Math.floor(Math.abs(Math.sin(i + 1)) * 4294967296));
  }
  return k;
})();

function rotl(x: number, c: number): number {
  return ((x << c) | (x >>> (32 - c))) | 0;
}

/**
 * 计算 MD5，返回 16 字节。
 * @param input 原始字节
 */
export function md5Bytes(input: number[]): number[] {
  const len = input.length;
  // padding：先补 0x80，再补若干 0，使 (len + 1 + padLen) % 64 == 56
  const padLen = ((56 - (len + 1) % 64) + 64) % 64;
  const total = len + 1 + padLen + 8;
  const msg: number[] = new Array<number>(total).fill(0);
  for (let i = 0; i < len; i++) {
    msg[i] = input[i] & 0xff;
  }
  msg[len] = 0x80;

  // 追加 64 位小端比特长度（高 32 位这里恒为 0，足够覆盖 512MB 以内的输入）
  const bitLen = len * 8;
  const lo = bitLen >>> 0;
  const hi = Math.floor(bitLen / 4294967296) >>> 0;
  const lenOff = total - 8;
  msg[lenOff] = lo & 0xff;
  msg[lenOff + 1] = (lo >>> 8) & 0xff;
  msg[lenOff + 2] = (lo >>> 16) & 0xff;
  msg[lenOff + 3] = (lo >>> 24) & 0xff;
  msg[lenOff + 4] = hi & 0xff;
  msg[lenOff + 5] = (hi >>> 8) & 0xff;
  msg[lenOff + 6] = (hi >>> 16) & 0xff;
  msg[lenOff + 7] = (hi >>> 24) & 0xff;

  let a0 = 0x67452301;
  let b0 = 0xefcdab89 | 0;
  let c0 = 0x98badcfe | 0;
  let d0 = 0x10325476;

  const m: number[] = new Array<number>(16).fill(0);
  for (let off = 0; off < total; off += 64) {
    for (let i = 0; i < 16; i++) {
      const j = off + i * 4;
      m[i] = (msg[j] | (msg[j + 1] << 8) | (msg[j + 2] << 16) | (msg[j + 3] << 24)) | 0;
    }
    let a = a0;
    let b = b0;
    let c = c0;
    let d = d0;

    for (let i = 0; i < 64; i++) {
      let f = 0;
      let g = 0;
      if (i < 16) {
        f = (b & c) | (~b & d);
        g = i;
      } else if (i < 32) {
        f = (b & d) | (c & ~d);
        g = (5 * i + 1) % 16;
      } else if (i < 48) {
        f = b ^ c ^ d;
        g = (3 * i + 5) % 16;
      } else {
        f = c ^ (b | ~d);
        g = (7 * i) % 16;
      }
      const tmp = d;
      d = c;
      c = b;
      const sum = (a + f + K[i] + m[g]) | 0;
      b = (b + rotl(sum, SHIFT[i])) | 0;
      a = tmp;
    }

    a0 = (a0 + a) | 0;
    b0 = (b0 + b) | 0;
    c0 = (c0 + c) | 0;
    d0 = (d0 + d) | 0;
  }

  const out: number[] = [];
  for (const w of [a0, b0, c0, d0]) {
    out.push(w & 0xff);
    out.push((w >>> 8) & 0xff);
    out.push((w >>> 16) & 0xff);
    out.push((w >>> 24) & 0xff);
  }
  return out;
}

function toHex(bytes: number[]): string {
  let s = '';
  for (const b of bytes) {
    const h = (b & 0xff).toString(16);
    s += h.length < 2 ? '0' + h : h;
  }
  return s;
}

/** 按 UTF-8 编码后取 MD5，返回小写 hex。 */
export function md5HexUtf8(text: string): string {
  return toHex(md5Bytes(utf8ToBytes(text)));
}

/** 对已有字节取 MD5，返回小写 hex。 */
export function md5HexBytes(bytes: number[]): string {
  return toHex(md5Bytes(bytes));
}

/** UTF-8 编码（含代理对处理）。 */
export function utf8ToBytes(s: string): number[] {
  const out: number[] = [];
  for (let i = 0; i < s.length; i++) {
    let cp = s.charCodeAt(i);
    if (cp >= 0xd800 && cp <= 0xdbff && i + 1 < s.length) {
      const lo = s.charCodeAt(i + 1);
      if (lo >= 0xdc00 && lo <= 0xdfff) {
        cp = 0x10000 + ((cp - 0xd800) << 10) + (lo - 0xdc00);
        i++;
      }
    }
    if (cp < 0x80) {
      out.push(cp);
    } else if (cp < 0x800) {
      out.push(0xc0 | (cp >> 6));
      out.push(0x80 | (cp & 0x3f));
    } else if (cp < 0x10000) {
      out.push(0xe0 | (cp >> 12));
      out.push(0x80 | ((cp >> 6) & 0x3f));
      out.push(0x80 | (cp & 0x3f));
    } else {
      out.push(0xf0 | (cp >> 18));
      out.push(0x80 | ((cp >> 12) & 0x3f));
      out.push(0x80 | ((cp >> 6) & 0x3f));
      out.push(0x80 | (cp & 0x3f));
    }
  }
  return out;
}
