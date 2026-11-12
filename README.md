# c001apk-compose-plus

c001apk-compose 的 MIUIX 界面迁移分支，个人学习用。

## 说明

- 非官方客户端，与酷安官方没有任何关系。
- 主体是 UI 迁移：把 Material 组件换成 [MIUIX](https://github.com/YuKongA/Miuix)；上游已停更（2024-09），
  因此网络层也做了少量必要适配（v3 签名、新版风控验证码闭环），详见下节。
- 主要容器已替换为 [Haze 2](https://github.com/chrisbanes/haze) 的液态玻璃（折射 / 色散 / Fresnel 高光），详见下节。
- 个人练手项目，**不保证可用性，也不承诺持续维护**。上游接口变动可能导致部分页面失效。
- 代码、图标与内容版权归原作者，使用请遵守 AGPL-3.0。
- 迁移过程踩到的版本问题记在 [BUILD_NOTES.md](BUILD_NOTES.md)、[MIUIX_MIGRATION.md](MIUIX_MIGRATION.md) 和两份 cheatsheet 里，供参考。

## 构建

| 项 | 版本 |
| --- | --- |
| JDK | 22 |
| Gradle | 9.6.0 |
| AGP | 9.4.1 |
| Kotlin | 2.4.21 |
| KSP | 2.3.12 |
| Compose Multiplatform | 1.12.2 |
| Compose BOM | 2026.09.00 |
| Haze (liquid glass) | 2.1.0 |
| compileSdk | 37 |
| minSdk | 24 |
| targetSdk | 35 |

版本需要严格对齐，AGP 9 / Kotlin 2.4 有破坏性变更，细节见 BUILD_NOTES。

```bash
# 国内网络默认走阿里云镜像，CI 上建议关掉
export USE_CN_MIRROR=false

./gradlew :app:assembleDebug
```

产物：`app/build/outputs/apk/`

## 模块

```
app/                     # 主应用（UI + 业务）
mojito/                  # 基础库（网络 / 数据 / 工具）
media-support/           # 媒体支持
SketchImageViewLoader/   # 图片加载器适配
```

## 迁移中遇到的问题

| 问题 | 处理 |
| --- | --- |
| Compose BOM 把 `ui` 降到 1.9.3 | 改用 `2026.09.00`，与 MIUIX 的 1.12.1 对齐 |
| `material-icons-extended` 没有 1.12.1 | 换回 AndroidX 1.7.8 |
| `miuix-blur` 要求 minSdk 33 | 与 minSdk 24 冲突，移除 |
| Compose 编译器坐标 | 用 `org.jetbrains.kotlin.plugin.compose` |

## 新版风控验证码（err_request_captcha_v2）

酷安 16.x 起 `/v6/feed/detail` 等接口会返回 `403 / 当前访问需要验证码`，
`messageStatus=err_request_captcha_v2`。这是网易易盾滑块风控，与旧的
`err_request_captcha`（发评论时的图形验证码）是两套机制。

本分支已接入完整闭环（思路参考 [WangMCweijia/c001apk PR #2](https://github.com/WangMCweijia/c001apk/pull/2)）：

- `CaptchaInterceptor` 识别风控响应 → 弹出应用内易盾滑块验证页 → 拿到 `validate`
  → 拼成 `NEC:<captchaId前8位>:<validate>` 写入 `validate` Cookie → **自动重放原请求**（GET 加 query / POST 加表单字段）。
- `validate` / `SESSID` 持久化在 `CaptchaStore`，重放仍命中风控时自动清除失效凭证。
- 详情接口被风控时仍继续加载评论（评论接口不受影响），不再整页空白。
- 反复触发验证时，可在「设置 → 数字联盟ID (ShuzlmID)」导入官方设备标识：
  打开官方酷安 OAID 页面连点 5 次「复制 OAID」，把多行日志直接粘贴进输入框即可自动提取。
  配置合法 ShuzlmID 后可稳定免验。

相关代码：`app/src/main/java/com/example/c001apk/compose/util/Captcha*.kt`、
`ui/captcha/CaptchaActivity.kt`、`logic/repository/NetworkRepo.kt`、`ui/settings/SettingsScreen.kt`。

## 液态玻璃 UI（Haze 2）

主要容器改用第三方 [chrisbanes/haze](https://github.com/chrisbanes/haze) 2.1.0 的
`haze-glass`（Apache-2.0），而不是自绘的毛玻璃：带真实折射、RGB 色散、Fresnel 边缘高光，
并按设备能力自动降级（AGSL / RenderEffect / CPU 模糊 / 纯渐变）。

- 根层：`MainActivity` 用 `ProvideGlass` 铺一层 `hazeSource` 背景层，全局共享 `GlassEnv.hazeState`；
  保持纯色主题背景（未加动态壁纸），玻璃质感来自折射与高光。
- 卡片式容器：`ui/theme/glass/Glass.kt` 提供与 MIUIX 签名兼容的 `Card` / `Surface`，
  设置页、关于页、通知页、聊天页等只需切换 import 即可获得玻璃效果。
- 信息流卡片：`glassBackground()` 作为普通 Modifier 扩展替换 `.background(cardBg())`，
  覆盖 FeedCard / FeedReplyCard 及各类 *Card；条件式背景用半透明 `cardBg()` 兜底。
- 版本对齐：Kotlin 2.4.21 / Compose Multiplatform 1.12.2，与 Haze 2.1.0 的编译版本一致。

> 注意：Haze 官方提示密集滚动列表里大量 Glass 面板会明显增加 GPU 开销。
> 当前为全量玻璃方案，低端机如出现掉帧，可在设置中关闭或把 `glassBackground()` 退回纯色。

## 已知问题

- 只测过 Android 手机，未适配平板 / 折叠屏。
- 少数页面仍是 Material 实现，视觉未完全统一。
- 没有做完整回归测试，个别功能可能不可用。
- 易盾验证页依赖 `cstaticdun.126.net` 可访问；网络受限时仍可退回手动导入 ShuzlmID 免验。
- 全屏液态玻璃在纯色背景上折射效果有限，且密集列表可能有性能开销（见上节）。

## License

AGPL-3.0（见 [LICENSE](./LICENSE)）。

## 致谢

- [YuKongA/Miuix](https://github.com/YuKongA/Miuix)
- [chrisbanes/haze](https://github.com/chrisbanes/haze)（液态玻璃效果库）
- c001apk-compose 原作者及贡献者
