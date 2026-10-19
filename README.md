<div align="center">

# c001apk-compose-plus

**酷安第三方客户端（Jetpack Compose）· MIUIX 全量 UI 迁移版**

在 [c001apk-compose](https://github.com/YuKongA) 的基础上，把整套界面迁移到 [MIUIX](https://github.com/YuKongA/Miuix)（MIUI / HyperOS 风格 Compose 组件库）。

[![Kotlin](https://img.shields.io/badge/Kotlin-2.4.20-7F52FF?style=flat-square&logo=kotlin)](https://kotlinlang.org/)
[![Compose](https://img.shields.io/badge/Compose-1.12.1-4285F4?style=flat-square)](https://developer.android.com/jetpack/compose)
[![MIUIX](https://img.shields.io/badge/MIUIX-0.9.4-orange?style=flat-square)](https://github.com/YuKongA/Miuix)
[![License](https://img.shields.io/badge/License-AGPL--3.0-blue?style=flat-square)](./LICENSE)

</div>

---

> 本项目是非官方第三方客户端，仅用于学习与测试，与酷安官方无任何关系。

## 简介

`c001apk-compose-plus` 保留了原项目的业务层与网络层，把 Material 组件体系**整体替换**为 MIUIX：

- 主题：`MaterialTheme` → `MiuixTheme`，支持 Monet 取色、AMOLED 纯黑、种子色
- 组件：按钮、开关、列表、对话框、下拉、导航、搜索框等全部换用 MIUIX 对应实现
- 交互：下拉刷新、Snackbar、Tab、BottomSheet 按 MIUIX 规范重做

迁移过程中遇到的版本矩阵与 API 差异，全部记录在 [MIUIX_MIGRATION.md](MIUIX_MIGRATION.md)、[BUILD_NOTES.md](BUILD_NOTES.md) 与两份 cheatsheet 里。

## 特性

| 能力 | 说明 |
| --- | --- |
| 首页 / 热榜 | 酷安 feed 流、热榜、关注 |
| 应用详情 | 应用信息、评分、评论、版本历史 |
| 动态与评论 | 图文动态、楼中楼评论、点赞/回复 |
| 搜索 | 应用、用户、动态搜索与筛选 |
| 个人中心 | 登录、收藏、关注、消息 |
| 主题 | Monet 系统取色 / 种子色 / 深色 / AMOLED 纯黑 |
| MIUIX 组件 | 全局 MIUIX 化，视觉与 HyperOS 对齐 |

## 构建

### 环境要求

| 组件 | 版本 |
| --- | --- |
| JDK | 21 |
| Gradle | 9.6.0 |
| AGP | 9.4.1 |
| Kotlin | 2.4.20 |
| KSP | 2.3.12 |
| compileSdk | 37（`android-37.2`） |
| minSdk | 24 |
| targetSdk | 35 |

> ⚠️ 版本必须严格对齐，AGP 9 / Kotlin 2.4 有破坏性变更。完整说明见 [BUILD_NOTES.md](BUILD_NOTES.md)。

### 命令

```bash
# 国内网络默认走阿里云镜像；CI 上用官方源
export USE_CN_MIRROR=false

./gradlew :app:assembleDebug
./gradlew :app:assembleRelease
./gradlew :app:lintDebug
```

产物：`app/build/outputs/apk/`

## 模块

```
c001apk-compose-plus/
├── app/                     # 主应用（Compose UI + 业务）
├── mojito/                  # 基础库（网络 / 数据 / 工具）
├── media-support/           # 图片/媒体支持
├── SketchImageViewLoader/   # Sketch 图片加载器适配
├── BUILD_NOTES.md           # AGP 9 / Kotlin 2.4 构建改动（8 项）
├── MIUIX_MIGRATION.md       # 组件映射表与迁移决策
├── MIUIX_API_CHEATSHEET.md  # MIUIX API 速查
└── MIUIX_DROPDOWN_CHEATSHEET.md
```

## 迁移要点

| 主题 | 结论 |
| --- | --- |
| 依赖坐标 | 核心 Compose 切到 `org.jetbrains.compose.*` 1.12.1 |
| BOM 陷阱 | Compose BOM `2025.10.00` 会把 `ui` 压到 1.9.3，必须用 `2026.09.00`（对齐 1.12.1） |
| material-icons | JetBrains 版最高 1.7.3，改用 AndroidX 1.7.8 |
| miuix-blur | 要求 minSdk 33，与 minSdk 24 冲突，已移除 |
| Compose 编译器 | 用 `org.jetbrains.kotlin.plugin.compose`（2.4.20），不是 `org.jetbrains.compose` |
| 字体缩放 | 保留 `LocalDensity` 覆盖，避免 MIUIX 默认缩放与系统设置冲突 |

## 已知限制

- 仅 Android；依赖酷安私有 API，接口变动可能导致部分页面失效
- 未做平板/折叠屏适配
- MIUIX 0.9.4 尚未覆盖的组件（如部分图表）仍保留 Material 实现

## 声明

本项目仅用于学习与测试，请勿用于商业用途。所有内容版权归酷安及原作者所有。

## License

AGPL-3.0

## 致谢

- [YuKongA/Miuix](https://github.com/YuKongA/Miuix) — MIUIX 组件库
- c001apk-compose 原作者与所有贡献者
