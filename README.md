# c001apk-compose-plus

c001apk-compose 的 MIUIX 界面迁移分支，个人学习用。

## 说明

- 非官方客户端，与酷安官方没有任何关系。
- 只动 UI 层：把 Material 组件换成 [MIUIX](https://github.com/YuKongA/Miuix)，业务与网络逻辑沿用上游。
- 个人练手项目，**不保证可用性，也不承诺持续维护**。上游接口变动可能导致部分页面失效。
- 代码、图标与内容版权归原作者，使用请遵守 AGPL-3.0。
- 迁移过程踩到的版本问题记在 [BUILD_NOTES.md](BUILD_NOTES.md)、[MIUIX_MIGRATION.md](MIUIX_MIGRATION.md) 和两份 cheatsheet 里，供参考。

## 构建

| 项 | 版本 |
| --- | --- |
| JDK | 22 |
| Gradle | 9.6.0 |
| AGP | 9.4.1 |
| Kotlin | 2.4.20 |
| KSP | 2.3.12 |
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

## 已知问题

- 只测过 Android 手机，未适配平板 / 折叠屏。
- 少数页面仍是 Material 实现，视觉未完全统一。
- 没有做完整回归测试，个别功能可能不可用。

## License

AGPL-3.0（见 [LICENSE](./LICENSE)）。

## 致谢

- [YuKongA/Miuix](https://github.com/YuKongA/Miuix)
- c001apk-compose 原作者及贡献者
