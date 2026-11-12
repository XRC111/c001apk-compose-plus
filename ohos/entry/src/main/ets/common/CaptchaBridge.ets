/**
 * 页面间传递验证参数。
 *
 * 与 Feed 的 pendingDetailId 同样的思路：用模块级变量而非 router 参数，
 * 避免 ArkTS 里 Object → 接口的类型转换问题。
 */

let pendingCaptchaId: string = '';

export function setPendingCaptchaId(id: string): void {
  pendingCaptchaId = id;
}

export function getPendingCaptchaId(): string {
  return pendingCaptchaId;
}

/** 由 Web 的 JS 代理调用，把易盾返回的 validate 交给页面。 */
export type ValidateCallback = (validate: string) => void;

let validateCallback: ValidateCallback | null = null;

export function setValidateCallback(cb: ValidateCallback): void {
  validateCallback = cb;
}

export function clearValidateCallback(): void {
  validateCallback = null;
}

export function dispatchValidate(validate: string): void {
  if (validateCallback !== null) {
    validateCallback(validate);
  }
}
