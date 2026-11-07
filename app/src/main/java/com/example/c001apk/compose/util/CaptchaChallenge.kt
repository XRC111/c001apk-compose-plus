package com.example.c001apk.compose.util

import com.google.gson.JsonObject
import com.google.gson.JsonParser

/**
 * 酷安新版风控：GET /v6/feed/detail 等接口返回
 * {"status":403,"message":"当前访问需要验证码","messageStatus":"err_request_captcha_v2", ...}
 *
 * 与旧的 err_request_captcha（发评论时的图形验证码，/v6/account/captchaImage）
 * 是两套完全不同的机制：新版走网易易盾滑块，验证凭证写进 validate Cookie 后重放请求。
 *
 * 解析逻辑与 WangMCweijia/c001apk PR #2 的 captcha_challenge.dart 保持一致。
 */
data class CaptchaChallenge(
    val captchaId: String,
    val field: String,
) {
    companion object {
        const val STATUS = "err_request_captcha_v2"
        const val DEFAULT_ID = "414e5c9b866a03db03f860a1a9101672"
        const val DEFAULT_FIELD = "_v2_post_token"

        private val ID_REGEX = Regex("^[a-zA-Z0-9]{16,64}$")
        private val FIELD_REGEX = Regex("^_[a-zA-Z0-9_]{1,63}$")
        private val UNSAFE_REGEX = Regex("[\\s\\x00-\\x1f]")

        /** 从响应原始 JSON 解析；非风控响应返回 null。 */
        fun fromBody(raw: String?): CaptchaChallenge? {
            if (raw.isNullOrBlank() || !raw.contains(STATUS)) return null
            val root = try {
                JsonParser.parseString(raw).takeIf { it.isJsonObject }?.asJsonObject
            } catch (e: Exception) {
                null
            } ?: return null
            if (root.get("messageStatus")?.takeIf { it.isJsonPrimitive }?.asString != STATUS) return null

            var extra: JsonObject? = null
            val extraNode = root.get("messageExtra") ?: root.get("extra")
            if (extraNode != null && extraNode.isJsonObject) {
                extra = extraNode.asJsonObject
            } else if (extraNode != null && extraNode.isJsonPrimitive) {
                extra = try {
                    JsonParser.parseString(extraNode.asString)
                        .takeIf { it.isJsonObject }?.asJsonObject
                } catch (e: Exception) {
                    null
                }
            }
            val source = extra ?: root

            val rawId = source.get("captchaId")?.takeIf { it.isJsonPrimitive }?.asString
            val id = if (rawId != null && ID_REGEX.matches(rawId)) rawId else DEFAULT_ID

            val rawField = source.get("captchaField")?.takeIf { it.isJsonPrimitive }?.asString
            val field = when {
                rawField == null -> DEFAULT_FIELD
                rawField.trim().isEmpty() -> ""
                FIELD_REGEX.matches(rawField.trim()) -> rawField.trim()
                else -> DEFAULT_FIELD
            }
            return CaptchaChallenge(id, field)
        }
    }

    /** 易盾回调拿到的 validate → 服务端要求的 NEC 凭证串。 */
    fun proof(validate: String?): String? {
        if (validate == null || validate.isEmpty() || validate.length > 8192) return null
        if (UNSAFE_REGEX.containsMatchIn(validate)) return null
        return "NEC:${captchaId.take(8)}:$validate"
    }

    fun acceptsProof(proof: String): Boolean =
        proof.startsWith("NEC:${captchaId.take(8)}:") &&
            proof.length > 13 &&
            proof.length <= 8205 &&
            !UNSAFE_REGEX.containsMatchIn(proof)
}
