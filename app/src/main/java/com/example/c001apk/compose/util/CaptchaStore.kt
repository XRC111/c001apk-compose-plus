package com.example.c001apk.compose.util

import android.content.SharedPreferences
import com.example.c001apk.compose.c001Application
import java.net.URLEncoder

/**
 * 验证码凭证与会话的持久化。
 *
 * 单独用 SharedPreferences 而不塞进 UserPreferences（proto DataStore），是因为这两个值由
 * OkHttp 拦截器在任意线程读写，需要同步可见；DataStore 的挂起 API 不适合拦截器热路径。
 */
object CaptchaStore {

    private const val FILE = "captcha_store"
    private const val KEY_VALIDATE = "validate"
    private const val KEY_SESSID = "sessid"

    private val prefs: SharedPreferences
        get() = c001Application.getSharedPreferences(FILE, android.content.Context.MODE_PRIVATE)

    @Volatile
    private var cachedValidate: String? = null

    @Volatile
    private var cachedSessid: String? = null

    init {
        cachedValidate = prefs.getString(KEY_VALIDATE, null)
        cachedSessid = prefs.getString(KEY_SESSID, null)
        if (!cachedSessid.isNullOrEmpty()) {
            CookieUtil.SESSID = cachedSessid!!
        }
    }

    val validate: String?
        get() = cachedValidate

    val sessid: String?
        get() = cachedSessid

    /** 保存易盾凭证（已做 URL 编码，可直接放进 Cookie）。 */
    fun setValidate(proof: String) {
        val encoded = URLEncoder.encode(proof, "UTF-8")
        cachedValidate = encoded
        prefs.edit().putString(KEY_VALIDATE, encoded).apply()
    }

    fun clearValidate() {
        cachedValidate = null
        prefs.edit().remove(KEY_VALIDATE).apply()
    }

    /** 服务端 Set-Cookie 下发 SESSID 时持久化，游客态请求也能带上。 */
    fun setSessid(value: String) {
        val cookie = if (value.startsWith("SESSID=")) value else "SESSID=$value"
        cachedSessid = cookie
        CookieUtil.SESSID = cookie
        prefs.edit().putString(KEY_SESSID, cookie).apply()
    }
}
