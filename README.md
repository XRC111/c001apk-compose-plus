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
ohos/                    # HarmonyOS 原生版（ArkTS / ArkUI，Stage 模型）
scripts/harmony/         # 鸿蒙 SDK 安装脚本（CI 用）
```

## HarmonyOS 原生版（实验）

`ohos/` 是独立的 ArkTS/ArkUI 原生实现，与 Android 版共用同一套酷安协议。

**已实现（均通过 CI 构建）**

协议与安全层，全部纯 ArkTS、零三方依赖：

- `Md5.ets` —— RFC 1321
- `StandardBase64.ets` —— 标准 base64 + Java `latin1→UTF-8` 语义模拟
- `Bcrypt.ets` —— Blowfish + EksBlowfish key schedule（cost=10），含 jBCrypt
  遇到非字母表字符时截断 salt 的宽容行为
- `CoolapkToken.ets` —— X-App-Token v3（16 秒向前探测重试）+ v2 兜底 + 完整请求头
- `AuthBlob.ets` —— 从 `libauth.so` 提取的 930 字符认证 blob
- `DeviceCode.ets` —— `X-App-Device` 生成（base64 反转去 `=`）
- `CookieStore.ets` —— 登录态（uid/username/token）+ SESSID + validate

功能页面与界面结构：

界面按 Android 版的 `MainScreen` 结构重做：**底部三栏（首页 / 消息 / 设置）**，
首页为「顶部栏 + 可横向滚动的分类 Tab + 卡片式信息流」。

| 页面 / 视图 | 说明 |
| --- | --- |
| `Index` | 应用外壳：底部三栏导航（图标 + 文字，选中态粉色） |
| `view/HomeTab` | 顶部栏（搜索入口）、分类 Tab（关注/应用/动态/热榜/话题/数码/酷图）、卡片式信息流、下拉刷新、分页加载 |
| `view/MessageTab` | 消息页：@我 / 评论 / 赞 / 粉丝 / 私信 五类，未读数徽标，触底分页 |
| `ChatPage` | 私信会话：气泡式对话（我方粉色 / 对方白色），自动滚到底部，可发送文字消息 |
| `view/SettingsTab` | 设置页（账号 / ShuzlmID / 设备码 / 关于） |
| `FeedDetail` | 动态详情：作者卡、正文、九宫格图片、评论列表（带头像） |
| `AppDetail` | 应用详情：图标、版本/大小/下载量、更新日志、介绍 |
| `UserPage` | 用户主页：头像、等级、简介、关注/粉丝/经验 |
| `SearchPage` | 关键词搜索（统一卡片样式） |
| `LoginPage` | 内置网页登录，页末自动提取 Cookie 并落盘 |
| `CaptchaPage` | 内嵌易盾滑块（`cstaticdun.126.net`），通过 `javaScriptProxy` 回传 `validate` |
| `About` | 能力清单与未实现项 |

信息流卡片：圆形头像（无头像时取昵称首字）、昵称 + 类型/时间元信息、正文（8 行截断、
`@用户` / `#话题#` / 链接 高亮）、单图大图 / 多图 `Grid` 九宫格、赞与评论计数（SVG 图标）、
应用类条目单独渲染为应用卡片（图标 / 名称 / 版本大小 / 下载量）。
图标为自绘 SVG（`resources/base/media/ic_*.svg`），用 `fillColor` 统一着色，深浅色自动换色；
图片统一挂 `.alt()` 占位图，避免加载时留白。应用图标为 512×512 品牌图（粉色渐变 + 白色「酷」）。
设置页用 `ListItemGroup` 分「账号 / 设备 / 其他」三组并开启 `sticky` 吸顶；
底部「消息」Tab 用 `Badge` 显示未读数。

列表项按 `entityType` 分流：`product` / `apk` 进应用详情，其余进动态详情；
动态详情里的作者名可点进用户主页。

**界面尚未覆盖**：点赞/收藏/评论等写操作、发现页、图片查看器。
`n> 图片缓存未单独实现：ArkUI 的 `Image` 组件自带解码缓存，`.alt()` 负责占位。

运行时细节：

- 命中 `err_request_captcha_v2` 时解析 `captchaId`，页面给出「去验证」入口，
  验证成功后 `validate` 落盘，后续请求自动带上
- 服务端下发的 `SESSID` 自动回写（风控重放必需）
- 深色模式：`resources/base/element/color.json` 与 `resources/dark/element/color.json`
  定义同名语义色，运行期由系统按深浅色自动切换；SVG 图标用 `fillColor` 跟随。
  `EntryAbility` 里 `setColorMode(COLOR_MODE_NOT_SET)` 跟随系统，并把 `colorMode`
  写入 `AppStorage`，`Index` 监听后调用 `setWindowSystemBarProperties` 调整状态栏文字色
- v3 token 有 3 秒短期缓存：单次生成要跑 bcrypt(cost=10)，手机上约数百毫秒，
  列表连续请求时逐次重算会明显卡顿

**正确性验证**（本地对拍，非 CI）：bcrypt 与 bcryptjs 6/6、ArkTS 移植版与已验证
JS 参考实现 30/30（含 `+` 在 salt 首/中/尾）、MD5 与 `node:crypto` 10/10、
v3 token 端到端 24/24 逐字符一致。

**构建**：GitHub Actions `Build HarmonyOS HAP`（`ohos/**` 变更或手动触发），
产物 `ohos/entry/build/default/outputs/default/entry-default-unsigned.hap`
（**未签名**，真机安装需自行用 DevEco 配签名）。

**尚未实现**：点赞收藏评论等写操作、消息通知与发现页、图片缓存与预加载。

> 注：所有功能只经过编译验证，**未在真机上做运行时验证**；易盾滑块与登录页
> 依赖 Web 组件与真实网络，需装机确认。

### 易盾滑块不弹出的排查（对齐 Android 版实现）

对比 Android 版 `CaptchaActivity` / `CaptchaChallenge` / `CaptchaInterceptor` 后，
修正了以下会导致滑块不渲染或验证无效的问题：

| 问题 | 修正 |
| --- | --- |
| 用 `$rawfile('captcha.html')` 加载，页面源是 `resource://` | 改为 `controller.loadData(html, 'text/html', 'UTF-8', baseUrl, historyUrl)`，`baseUrl=https://www.coolapk.com/`（与 Android 的 `loadDataWithBaseURL` 一致）；易盾会校验页面域名与 captchaId 绑定域 |
| `captchaId` 只从顶层正则取，取不到就是空串 | 新增 `CaptchaChallenge.ets`：从 `messageExtra` / `extra`（也可能是嵌套 JSON 字符串）解析，取不到用默认 ID `414e5c9b866a03db03f860a1a9101672`，并保留 `captchaField` |
| `validate` 存的是裸串 | 按 Android 的 `proof()` 存成 `NEC:<captchaId前8位>:<validate>` |
| 验证完没有重放原请求 | 验证成功写 `AppStorage.captchaDoneTick`，各页 `@StorageProp @Watch` 监听后自动重新拉取；网络层请求自动按 `captchaField` 追加凭证 query，并写入 `validate` Cookie |
| WebView UA / 混合内容 | 设置与 API 层一致的 User-Agent、`mixedMode(MixedMode.All)`，并加「重新加载」按钮 |

> 注意：以上只经过编译验证，**易盾能否真正弹出需在真机确认**（依赖网络、域名绑定与
> captchaId 有效性）。若仍不弹，优先看页面内 `#status` 的提示文字定位到哪一步失败。
### 踩坑：hvigor `00303024 项目结构需要升级`

根 `oh-package.json5` 与 `hvigor/hvigor-config.json5` **都必须有 `modelVersion`，
且两者必须完全相等**。任一缺失都会抛该错误，与 modelVersion 具体取值无关
（hvigor 的 `ValidateUtil.modelVersionCheck` 同时读这两处，缺失即走 else 分支）。
合法范围为 `[5.0.0, 当前 SDK 版本]`，本项目两处均为 `6.0.0`。

## 迁移中遇到的问题

| 问题 | 处理 |
| --- | --- |
| Compose BOM 把 `ui` 降到 1.9.3 | 改用 `2026.09.00`，与 MIUIX 的 1.12.1 对齐 |
| `material-icons-extended` 没有 1.12.1 | 换回 AndroidX 1.7.8 |
| `miuix-blur` 要求 minSdk 33 | 与 minSdk 24 冲突，移除 |
| Compose 编译器坐标 | 用 `org.jetbrains.kotlin.plugin.compose` |
| 鸿蒙 `00303024` | 见上节：两处 `modelVersion` 必须都存在且相等 |

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
