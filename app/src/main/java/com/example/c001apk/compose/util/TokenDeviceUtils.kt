package com.example.c001apk.compose.util

import android.util.Base64
import com.example.c001apk.compose.constant.Constants
import com.example.c001apk.compose.constant.Constants.EMPTY_STRING
import com.example.c001apk.compose.util.Utils.getBase64
import com.example.c001apk.compose.util.Utils.getMD5
import org.mindrot.jbcrypt.BCrypt
import java.nio.charset.Charset
import java.nio.charset.StandardCharsets
import java.util.Random


object TokenDeviceUtils {

    fun encode(deviceInfo: String): String {
        val charset: Charset = StandardCharsets.UTF_8
        val bytes = deviceInfo.toByteArray(charset)
        val encodeToString = Base64.encodeToString(bytes, 0)
        val replace = StringBuilder(encodeToString).reverse().toString()
        return Regex("\\r\\n|\\r|\\n|=").replace(replace, EMPTY_STRING)
    }

    fun randHexString(@Suppress("SameParameterValue") n: Int): String {
        Random().setSeed(System.currentTimeMillis())
        return (0 until n).joinToString("") {
            Random().nextInt(256).toString(16)
        }.uppercase()
    }

    /**
     * 酷安 X-App-Token v3。
     *
     * 背景：酷安 16.x 起把 token 从 v2 升级到 v3。服务端会校验版本，
     * 用 v2 请求 `/v6/feed/replyList` 等接口会返回
     * `{"status":403,"message":"评论接口异常，请尝试升级到新版酷安"}`。
     *
     * v3 与 v2 的差异：salt 里不再用时间戳的 base64，而是从一个内嵌
     * blob 中按 `((ts + versionCode) % 100) * 4 + 0x80` 切片取出 segment，
     * 参与 plain 的构造，最后 bcrypt(cost=10) 后 Base64。
     *
     * 算法来源：https://github.com/qiuyurs/coolApkAPI
     *          https://github.com/Lniosy/coolapk-mcp
     * blob 来自官方 APK 的 lib/arm64-v8a/libauth.so（base64 + XOR 0x5A 解码）。
     */
    fun String.getTokenV3(): String {
        val deviceCode = this
        val pkg = Constants.APP_ID
        val versionCode = Constants.VERSION_CODE

        val start = System.currentTimeMillis() / 1000L
        // bcrypt 对部分 salt 会报 Invalid salt，向前探几秒规避
        for (offset in 0..15) {
            val ts = start + offset
            runCatching { buildTokenV3(deviceCode, ts, versionCode, pkg) }
                .getOrNull()
                ?.let { return it }
        }
        // 全部失败则退回 v2，避免请求头为空
        return deviceCode.getTokenV2()
    }

    private fun buildTokenV3(
        deviceCode: String,
        ts: Long,
        versionCode: String,
        pkg: String,
    ): String {
        val blob = AUTH_BLOB

        val idx = ((ts + versionCode.toLong()) % 100).toInt() * 4 + 0x80
        require(idx + 0x80 <= blob.size) { "blob index out of range" }
        val chunk = blob.copyOfRange(idx, idx + 0x80)

        val segment = Base64.decode(String(chunk, StandardCharsets.ISO_8859_1).trim(), Base64.DEFAULT)

        val plain = buildList<Byte> {
            addAll(pkg.toByteArray(StandardCharsets.UTF_8))
            add('&'.code.toByte())
            addAll(segment)
            add('&'.code.toByte())
            addAll(deviceCode.getMD5().toByteArray(StandardCharsets.US_ASCII))
            add('&'.code.toByte())
            addAll(ts.toString().toByteArray(StandardCharsets.US_ASCII))
            add('&'.code.toByte())
            addAll(versionCode.toByteArray(StandardCharsets.US_ASCII))
        }.toByteArray()

        // bcrypt 的口令
        val pw = Base64.encodeToString(plain, Base64.NO_WRAP).getMD5()

        // salt: base64(hex(ts)/md5(plain))[:22]，末位在标准 base64 表上偏移 -5
        val plainMd5 = String(plain, StandardCharsets.ISO_8859_1).getMD5()
        val saltSrc = Base64.encodeToString(
            "${java.lang.Long.toHexString(ts)}/$plainMd5".toByteArray(StandardCharsets.US_ASCII),
            Base64.NO_WRAP
        ).replace("=", "")
        val salt22 = shiftLastB64Char(saltSrc.substring(0, 22), -5)

        // jbcrypt 只认 $2a$，生成后把前缀换成 $2y$
        val hashed = BCrypt.hashpw(pw, "\$2a\$10\$$salt22")
        val bcryptResult = "\$2y\$${hashed.substring(4)}"

        return "v3" + Base64.encodeToString(
            bcryptResult.toByteArray(StandardCharsets.US_ASCII), Base64.NO_WRAP
        ).replace("=", "")
    }

    private const val STD_B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    private fun shiftLastB64Char(s: String, shift: Int): String {
        val idx = STD_B64.indexOf(s.last())
        val ni = ((idx + shift) % 64 + 64) % 64
        return s.dropLast(1) + STD_B64[ni]
    }

    /**
     * 从 libauth.so 提取的认证 blob（已 base64 + XOR 0x5A 解密，共 930 字节）。
     * 内容为长 base64 文本，按 `((ts+versionCode)%100)*4+0x80` 切片后每片 128 字节。
     */
    private const val AUTH_BLOB_B64 = 
        "VFRCVU9GUXNRMEVsTFVNa1dERWpRU0VzVXlFbUxETkFVeTFEUEZZdUl5MGlNVU01SXpCVUpGY3RNeWtoTVVRMUpTMURPU1V4TXpo" +
        "UUxWTXdWMDBzSXloU01UUXNXVEZEUkZFd1EwUlZNU1FrVVMwaktTTXRKRGhZTFZRa1VqRXpLU1FzTTBCVkxUUXdVaTAwTlNNc00y" +
        "QlhMVk1sSkMxRE5GbE5MQ1EwV1RFekxTUXhRMEVoTEVNbElqRXpLRmN3TXowbExpTkVWekVqUFNZdU5Ea2tMRk13Vml4VEtGa3RR" +
        "emhYTEZNc1dDNGpMU1l0VTJCVFRUQTBMRkV1TXpoVExqTWhJakZETUZNc0kwQlZMQ1FrVUN3ekpTSXNJekJTTUVNOFVDeEVMU0l0" +
        "STJCUUxVUW9VeTBqTEZNc0l5VWtNRlF3VmswdFJDeFlNVE1sSkM0ME5TRXdVMFJRTEZNaElpMGtOU013VTJCUUxqTmdVeXdqT0ZF" +
        "c05DeFRMRU13V0N4VUxTRXRJeVJUTEROQkl5MDBKRlpOTVVNc1VEQkVKRmd0TkMwa0xEUWtXQzFETUZNeFJDa2pMVk0wVml4VE1G" +
        "Z3hJeTBtTFZNeEpTMHpKRlF4TTJCUUxTUTRXVEJETUZNdUkwVWhUU3d6UEZndFJEQlJNRE5FVVMwak9GWXVKRGtsTVNRMFV6QXpO" +
        "U013UkRra01UTWtWU3hVTUZRdFJDeFlNVE5GSXl4RUxGWXNJelVoTGlRMFYwMHhOQ3hWTENNMFZ5NHpKRlV4TkN4VExGUTRWeTRq" +
        "WUZZeEpEVWpMVU13VXpGRFBGSXNNMEVsTERNc1ZEQTBPU011TkNrbUxFUWtWaXhFTVNKTkxUTW9VaXd6TEZjdFUwUlFMaVF3VlRG" +
        "REpTVXdVeWtqTVVNaEl5MHpJU1VzSTBFak1UTXdVUzFVTkZjeFJERWxMVVF0SlM0a05GSXNJemhaVFRCVFlGRXdReVJZTFNNbElT" +
        "NDBMRmdzVkRSWkxVUW9XVEJEUUZZdFJDeFdMak5FVkRCRE1Ga3RORFVsTEZRNFZTMVVKRmd3TXpSV0xEUTRVVTB3UXkwbUxVUTRX" +
        "UzFUTVNNc1V5VWlNVU5BVVN4VUxGWXVJMFJVTGlNc1dERkVMRk14STJCUUxWTTBXUzRrT0Zjd00wUlhMVk1vV0MwaktGRXhMQ00w" +
        "Vml4VE5GQXRSRFJXTFVRbEpDMVRKRkF3TkN4Z1lB"

    private val AUTH_BLOB: ByteArray by lazy { AUTH_BLOB_B64.decodeBase64NoWrap() }

    private fun String.decodeBase64NoWrap(): ByteArray =
        Base64.decode(this, Base64.NO_WRAP)

    fun String.getTokenV2(): String {
        val timeStamp = (System.currentTimeMillis() / 1000f).toString()

        val base64TimeStamp = timeStamp.getBase64()
        val md5TimeStamp = timeStamp.getMD5()
        val md5DeviceCode = this.getMD5()

        val token = "${Constants.APP_LABEL}?$md5TimeStamp$$md5DeviceCode&${Constants.APP_ID}"
        val base64Token = token.getBase64()
        val md5Base64Token = base64Token.getMD5()
        val md5Token = token.getMD5()

        val bcryptSalt = "${"$2a$10$$base64TimeStamp/$md5Token".substring(0, 31)}u"
        val bcryptResult = BCrypt.hashpw(md5Base64Token, bcryptSalt)

        return "v2${bcryptResult.replaceRange(0, 3, "$2y").getBase64()}"
    }

}
