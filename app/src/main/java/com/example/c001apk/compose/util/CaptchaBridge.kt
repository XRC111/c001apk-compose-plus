package com.example.c001apk.compose.util

import android.content.Intent
import com.example.c001apk.compose.c001Application
import com.example.c001apk.compose.ui.captcha.CaptchaActivity
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeout
import java.util.concurrent.atomic.AtomicReference

/**
 * 网络线程（OkHttp 拦截器，同步）与 UI（易盾 WebView Activity）之间的桥。
 *
 * 拦截器命中 err_request_captcha_v2 后调用 [awaitProofBlocking]，内部：
 *   1. 用 Mutex 合并并发请求——同一时刻只弹一个验证页，所有等待者共享同一个结果；
 *   2. 启动 CaptchaActivity（FLAG_ACTIVITY_NEW_TASK，不依赖当前 Activity）；
 *   3. 挂起等待用户完成滑块；Activity 通过 [submit] 把 validate 送回来；
 *   4. 有超时兜底（5 分钟），避免用户直接杀掉页面时网络线程永久卡死。
 *
 * 之所以允许在 OkHttp dispatcher 线程上 runBlocking：验证页跑在 main 线程 + WebView，
 * 不依赖被阻塞的那个 dispatcher 线程，因此不会形成环路死锁；OkHttp 线程池默认 64 线程，
 * 短暂占用一个是可接受的。
 */
object CaptchaBridge {

    private const val TIMEOUT_MS = 5 * 60 * 1000L

    private val mutex = Mutex()
    private val pending = AtomicReference<CompletableDeferred<String?>?>(null)
    private val challengeRef = AtomicReference<CaptchaChallenge?>(null)

    /** 挂起版，供协程侧使用。 */
    suspend fun awaitProof(challenge: CaptchaChallenge): String? {
        val deferred: CompletableDeferred<String?> = mutex.withLock {
            val existing = pending.get()
            if (existing != null) {
                existing
            } else {
                val newDeferred = CompletableDeferred<String?>()
                pending.set(newDeferred)
                challengeRef.set(challenge)
                launchUi(challenge)
                newDeferred
            }
        }
        return try {
            withTimeout(TIMEOUT_MS) { deferred.await() }
        } catch (e: TimeoutCancellationException) {
            reset()
            null
        }
    }

    /** 同步版，供 OkHttp 拦截器使用。 */
    fun awaitProofBlocking(challenge: CaptchaChallenge): String? = runBlocking {
        awaitProof(challenge)
    }

    /** 当前待验证的 challenge，供 Activity 读取。 */
    fun currentChallenge(): CaptchaChallenge? = challengeRef.get()

    /** 易盾验证完成（或用户取消）时由 Activity 调用。 */
    fun submit(validate: String?) {
        pending.get()?.complete(validate)
        reset()
    }

    private fun reset() {
        pending.set(null)
        challengeRef.set(null)
    }

    private fun launchUi(challenge: CaptchaChallenge) {
        val intent = Intent(c001Application, CaptchaActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra(CaptchaActivity.EXTRA_CAPTCHA_ID, challenge.captchaId)
            putExtra(CaptchaActivity.EXTRA_FIELD, challenge.field)
        }
        c001Application.startActivity(intent)
    }
}
