package com.example.c001apk.compose.util

import okhttp3.FormBody
import okhttp3.Interceptor
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.Response
import java.io.IOException

/**
 * 新版酷安风控闭环：识别 err_request_captcha_v2 → 应用内易盾验证 → 写 validate Cookie → 自动重放。
 *
 * 必须作为**最外层** application interceptor 注册（在 AddCookiesInterceptor 之前），
 * 这样重放请求会重新经过 AddCookiesInterceptor，自动带上刚写入的 validate Cookie 与全套签名头。
 * OkHttp 的 application interceptor 允许对同一个 chain 多次调用 proceed（限制只针对 network interceptor）。
 */
object CaptchaInterceptor : Interceptor {

    /** 标记已重放过的请求，避免验证失败时无限循环弹验证页。 */
    class RetriedTag

    private const val PEEK_BYTES = 256 * 1024L
    private val API_HOSTS = setOf("api.coolapk.com", "api2.coolapk.com")

    @Throws(IOException::class)
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        var response = chain.proceed(request)

        // 持久化服务端下发的 SESSID（游客态复核 / 风控会话需要）
        captureSessid(request, response)

        if (!shouldHandle(request)) return response

        val body = try {
            response.peekBody(PEEK_BYTES).string()
        } catch (e: Exception) {
            return response
        }
        val challenge = CaptchaChallenge.fromBody(body) ?: return response

        if (challenge.field.isEmpty()) {
            CaptchaStore.clearValidate()
        }
        val proof = CaptchaBridge.awaitProofBlocking(challenge)
        if (proof.isNullOrEmpty() || !challenge.acceptsProof(proof)) {
            return response
        }

        CaptchaStore.setValidate(proof)
        val retryRequest = buildRetry(request, challenge, proof)
        val retried = try {
            chain.proceed(retryRequest)
        } catch (e: Exception) {
            return response
        }

        // 重放后仍是风控：清掉失效凭证，返回重放结果由上层展示
        val retriedBody = try {
            retried.peekBody(PEEK_BYTES).string()
        } catch (e: Exception) {
            ""
        }
        if (CaptchaChallenge.fromBody(retriedBody) != null) {
            CaptchaStore.clearValidate()
        }
        response.close()
        return retried
    }

    private fun shouldHandle(request: Request): Boolean {
        if (request.tag(RetriedTag::class.java) != null) return false
        if (request.url.scheme != "https") return false
        return request.url.host in API_HOSTS
    }

    private fun captureSessid(request: Request, response: Response) {
        if (request.url.host !in API_HOSTS) return
        for (raw in response.headers("Set-Cookie")) {
            val cookie = raw.substringBefore(';').trim()
            if (cookie.startsWith("SESSID=") && cookie.length > 7) {
                CaptchaStore.setSessid(cookie)
            }
        }
    }

    /** 把 NEC 凭证按服务端要求塞进请求：GET 加 query，POST 加表单字段。 */
    private fun buildRetry(
        request: Request,
        challenge: CaptchaChallenge,
        proof: String,
    ): Request {
        val builder = request.newBuilder().tag(RetriedTag::class.java, RetriedTag())
        val field = challenge.field
        if (field.isEmpty()) {
            // 凭证只通过 validate Cookie 传递，请求本身不变
            return builder.build()
        }
        when (request.method) {
            "GET" -> {
                builder.url(
                    request.url.newBuilder()
                        .setQueryParameter(field, proof)
                        .build()
                )
            }
            "POST" -> {
                val body = request.body
                if (body is FormBody) {
                    val form = FormBody.Builder()
                    for (i in 0 until body.size) {
                        if (body.name(i) != field) {
                            form.add(body.name(i), body.value(i))
                        }
                    }
                    form.add(field, proof)
                    builder.post(form.build())
                } else if (body is RequestBody) {
                    // 非表单 POST（如 multipart）：退化为 query 参数
                    builder.url(
                        request.url.newBuilder()
                            .setQueryParameter(field, proof)
                            .build()
                    )
                }
            }
            else -> {
                builder.url(
                    request.url.newBuilder()
                        .setQueryParameter(field, proof)
                        .build()
                )
            }
        }
        return builder.build()
    }
}
