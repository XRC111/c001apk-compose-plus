package com.example.c001apk.compose.util

/**
 * 从官方酷安「复制 OAID」的多行日志里提取 ShuzlmID。
 * 与 WangMCweijia/c001apk PR #2 的 GStorage.extractSzlmId 一致。
 */
object SzlmIdExtractor {

    private val ID_REGEX = Regex(
        """ShuzlmID\s*[:：]\s*([A-Za-z0-9+/.=-]{8,})""",
        RegexOption.IGNORE_CASE,
    )

    fun extract(raw: String): String {
        val text = raw.replace("\uFEFF", "").trim()
        if (text.isEmpty()) return ""
        ID_REGEX.find(text)?.groupValues?.getOrNull(1)?.trim()?.let { return it }
        if (text.contains('\n') || text.contains('\r') || text.contains(':')) return ""
        if (text.equals("null", true) || text.equals("undefined", true)) return ""
        return text.replace(";", "")
    }
}
