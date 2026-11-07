package com.example.c001apk.compose.ui.captcha

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.WebSettings
import android.webkit.WebView
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.example.c001apk.compose.R
import com.example.c001apk.compose.util.CaptchaBridge
import com.example.c001apk.compose.util.CaptchaChallenge
import com.example.c001apk.compose.util.CookieUtil
import com.google.android.material.dialog.MaterialAlertDialogBuilder

/**
 * 应用内网易易盾滑块验证页。
 *
 * 独立于 Compose 导航栈，由 CaptchaBridge 以 FLAG_ACTIVITY_NEW_TASK 启动，
 * 因此网络拦截器命中风控时无需关心当前在哪个页面。
 * 验证结果通过 CaptchaBridge.submit 回传给等待中的 OkHttp 线程。
 */
class CaptchaActivity : Activity() {

    companion object {
        const val EXTRA_CAPTCHA_ID = "captcha_id"
        const val EXTRA_FIELD = "captcha_field"
        private const val BASE_URL = "https://www.coolapk.com/"

        private const val MATCH_PARENT = LinearLayout.LayoutParams.MATCH_PARENT
        private const val WRAP_CONTENT = LinearLayout.LayoutParams.WRAP_CONTENT
    }

    private lateinit var webView: WebView
    private lateinit var statusText: TextView
    private var finished = false
    private var captchaId: String = CaptchaChallenge.DEFAULT_ID
    private var field: String = CaptchaChallenge.DEFAULT_FIELD

    @SuppressLint("SetJavaScriptEnabled", "JavascriptInterface")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setTheme(R.style.Theme_C001apkCompose)
        captchaId = intent.getStringExtra(EXTRA_CAPTCHA_ID) ?: CaptchaChallenge.DEFAULT_ID
        field = intent.getStringExtra(EXTRA_FIELD) ?: CaptchaChallenge.DEFAULT_FIELD
        title = "人机验证"

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.TRANSPARENT)
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        statusText = TextView(this).apply {
            text = "正在加载验证组件…"
            setPadding(24, 24, 24, 8)
            textSize = 14f
            gravity = Gravity.CENTER_HORIZONTAL
        }
        root.addView(statusText, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT))

        val actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(16, 0, 16, 8)
        }
        actions.addView(Button(this).apply {
            text = "免验证说明"
            setOnClickListener { showHelp() }
        })
        actions.addView(Button(this).apply {
            text = "重新加载"
            setOnClickListener { loadCaptcha() }
        })
        actions.addView(Button(this).apply {
            text = "取消"
            setOnClickListener { finishWith(null) }
        })
        root.addView(actions, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT))

        webView = WebView(this).apply {
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, 0, 1f)
            settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                cacheMode = WebSettings.LOAD_NO_CACHE
                useWideViewPort = true
                loadWithOverviewMode = true
                javaScriptCanOpenWindowsAutomatically = false
                allowFileAccess = false
                if (CookieUtil.userAgent.isNotEmpty()) {
                    userAgentString = CookieUtil.userAgent
                }
            }
            addJavascriptInterface(object {
                @JavascriptInterface
                fun onVerified(validate: String?) {
                    runOnUiThread { finishWith(validate) }
                }
            }, "CaptchaBridge")
        }
        root.addView(webView)

        setContentView(root)
        loadCaptcha()
    }

    private fun status(text: String) {
        statusText.text = text
    }

    private fun loadCaptcha() {
        finished = false
        webView.loadDataWithBaseURL(BASE_URL, buildHtml(), "text/html", "utf-8", null)
    }

    /** 易盾 initNECaptcha 内嵌页，与 WangMCweijia/c001apk PR #2 的 captcha_page.dart 同协议。 */
    private fun buildHtml(): String = """
<!doctype html><html lang="zh-CN"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<style>html,body{font:15px sans-serif;margin:16px;color:#333}#captcha{margin-top:20px}</style>
</head><body><div id="captcha"></div>
<script>
function statusText(t){document.getElementById('captcha').innerHTML='<p>'+t+'</p>';}
function startCaptcha(){
  var timeout=setTimeout(function(){statusText('验证组件加载超时，请点击「重新加载」');},15000);
  var script=document.createElement('script');
  script.src='https://cstaticdun.126.net/load.min.js';
  script.onerror=function(){clearTimeout(timeout);statusText('验证组件加载失败，请检查网络后重新加载');};
  script.onload=function(){
    if(typeof initNECaptcha!=='function'){clearTimeout(timeout);statusText('验证组件不可用，请重新加载');return;}
    try{
      initNECaptcha({
        captchaId:'$captchaId',element:'#captcha',protocol:'https',
        mode:'embed',apiVersion:2,width:Math.min(320,window.innerWidth-32)+'px',lang:'zh-CN',
        onVerify:function(err,data){
          if(!err && data && data.validate){
            clearTimeout(timeout);
            window.CaptchaBridge.onVerified(data.validate);
          }else{
            statusText('验证未通过，请按提示重试');
          }
        }
      },function(){clearTimeout(timeout);},function(){clearTimeout(timeout);statusText('请按提示完成人机验证');});
    }catch(e){clearTimeout(timeout);statusText('验证组件初始化失败，请重新加载');}
  };
  document.head.appendChild(script);
}
window.addEventListener('load',startCaptcha);
</script></body></html>
""".trimIndent()

    private fun showHelp() {
        MaterialAlertDialogBuilder(this)
            .setTitle("反复出现人机验证？")
            .setMessage(
                "可在「设置 → 数字联盟ID」导入官方设备标识：\n" +
                    "1. 打开官方酷安 OAID 页面（检查日志和测试）\n" +
                    "2. 连续点击「复制 OAID」5 次\n" +
                    "3. 返回本应用粘贴保存即可免除大部分人机验证。"
            )
            .setPositiveButton("打开官方酷安 OAID 页") { _, _ -> openOfficialIdSettings() }
            .setNegativeButton("知道了", null)
            .show()
    }

    private fun openOfficialIdSettings() {
        try {
            packageManager.getApplicationInfo("com.coolapk.market", 0)
            startActivity(
                Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("coolmarket://www.coolapk.com/native/testSettings")
                ).setPackage("com.coolapk.market")
            )
        } catch (e: Exception) {
            MaterialAlertDialogBuilder(this)
                .setMessage("未安装官方酷安客户端")
                .setPositiveButton(android.R.string.ok, null)
                .show()
        }
    }

    private fun finishWith(validate: String?) {
        if (finished) return
        finished = true
        val challenge = CaptchaChallenge(captchaId, field)
        val proof = validate?.let { challenge.proof(it) }
        if (proof != null && challenge.acceptsProof(proof)) {
            CaptchaBridge.submit(proof)
        } else {
            CaptchaBridge.submit(null)
        }
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        finishWith(null)
    }

    override fun onDestroy() {
        webView.destroy()
        if (!finished) {
            CaptchaBridge.submit(null)
            finished = true
        }
        super.onDestroy()
    }
}
