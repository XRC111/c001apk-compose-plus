# 构建配置说明（MIUIX 迁移配套）

本文件记录 **MIUIX 全量迁移**过程中，为升级到 MIUIX 官方版本矩阵而必须做的构建配置改动。
这些改动大多是 **AGP 9 / Kotlin 2.4.20 的破坏性变更**，与 UI 迁移本身无关，但不改就无法编译。

---

## 1. 目标版本矩阵

与 MIUIX(`YuKongA/Miuix`) 官方 `libs.versions.toml` 对齐：

| 组件 | 版本 |
|---|---|
| Gradle | **9.6.0** |
| AGP | **9.4.1** |
| Kotlin | **2.4.20** |
| KSP | **2.3.12** |
| Compose Compiler 插件 | **1.12.1** |
| Compose BOM | **2026.09.00** |
| Hilt | **2.60.1** |
| protobuf 插件 | **0.10.0** |
| MIUIX | **0.9.4** |

Android SDK 要求：

```
compileSdk = 37        (platforms;android-37.2)
buildToolsVersion = 37.0.0
minSdk = 24            ← 不可提高到 33，见 §3
targetSdk = 35
```

---

## 2. 必须的构建配置改动（共 8 项）

### 2.1 Gradle 9.1.0 → 9.6.0

**原因**：AGP 9.4.1 的 `com.android.internal.version-check` 强制要求 Gradle ≥ 9.6.0。

```
Minimum supported Gradle version is 9.6.0. Current version is 9.1.0.
```

**改动**：`gradle/wrapper/gradle-wrapper.properties`

```properties
# 国内网络可用腾讯镜像；CI 上建议改回官方源
distributionUrl=https\://mirrors.cloud.tencent.com/gradle/gradle-9.6.0-bin.zip
# 官方源：
# distributionUrl=https\://services.gradle.org/distributions/gradle-9.6.0-bin.zip
```

### 2.2 KSP `2.4.20-2.0.2` → `2.3.12`

**原因**：KSP 已放弃 `<kotlin>-<ksp>` 的版本号方案，改为**独立版本号**。
`2.4.20-2.0.2` 这个版本**根本不存在**（Maven 上 404）。当前最新为 `2.3.12`。

**改动**：`gradle/libs.versions.toml`

```toml
ksp = "2.3.12"
```

> 注意：KSP 的独立版本号与 Kotlin 版本**不再一一对应**，升级 Kotlin 时不必同步升 KSP。

### 2.3 移除 `org.jetbrains.kotlin.android` 插件（4 个模块）

**原因**：**AGP 9.0 起内置 Kotlin 支持**，再声明该插件会直接报错：

```
The 'org.jetbrains.kotlin.android' plugin is no longer required for Kotlin support since AGP 9.0.
```

**改动**：以下文件的 `plugins {}` 中移除该插件
- `build.gradle.kts`（根，`apply false` 那行）
- `app/build.gradle.kts`
- `media-support/build.gradle.kts`（`id("kotlin-android")`）
- `mojito/build.gradle.kts`（`id("kotlin-android")`）
- `SketchImageViewLoader/build.gradle.kts`（`id("kotlin-android")`）

保留 `org.jetbrains.kotlin.plugin.compose`（Compose 编译器插件）和 `kotlin.parcelize`。

### 2.4 `packagingOptions` → `packaging`

**原因**：AGP 9 重命名。

```kotlin
// 旧
packagingOptions.resources.excludes += setOf(...)
// 新
packaging {
    resources.excludes += setOf(...)
}
```

### 2.5 移除 `applicationVariants` 变体配置

**原因**：AGP 9 移除了 `applicationVariants` API（连带 `outputs`、`ApkVariantOutputImpl`）。
原代码用于给 release APK 改名，**不影响功能**，直接移除。

```kotlin
// 已删除：
applicationVariants.configureEach {
    outputs.configureEach {
        if (baseName == "release") (this as? ApkVariantOutputImpl)?.outputFileName = ...
    }
}
```

> 若日后需要自定义 APK 名，应改用 `androidComponents { onVariants { ... } }`。

### 2.6 protobuf 插件 `0.9.6` → `0.10.0`

**原因**：**这是最隐蔽的一个**。protobuf-gradle-plugin `0.9.6` 内部强转旧 API：

```
Cannot cast object 'ApplicationExtensionImpl$AgpDecorated_Decorated'
  to class 'com.android.build.gradle.BaseExtension'
```

AGP 9 移除了 `BaseExtension`，而 `0.9.6` 是当时 Maven 上的"最新版"——但它之后的版本号**跳到了 `0.10.0`**（不是 0.9.7），很容易查漏。

**改动**：`gradle/libs.versions.toml`

```toml
protobufPlugin = "0.10.0"
```

同时**恢复** `app/build.gradle.kts` 中被临时注释掉的两处：
- `plugins {}` 里的 `alias(libs.plugins.google.protobuf)`
- 文件末尾的 `protobuf { protoc { ... } generateProtoTasks { ... } }` 配置块

> 排查过程中曾临时禁用 protobuf 插件，导致 `ThemeType`、`FollowType`、`UserPreferences`
> 等**生成类全部消失**，进而引发上百个 "Unresolved reference" 连锁错误——
> 那些错误**不是迁移问题**，恢复插件后即消失。

### 2.7 compileSdk 35 → 37

**原因**：MIUIX 0.9.4 的 AAR metadata 要求调用方 `compileSdk ≥ 37`：

```
Dependency 'top.yukonga.miuix.kmp:miuix-ui-android:0.9.4' requires
libraries and applications that depend on it to compile against
version 37 or later of the Android APIs. :app is currently compiled against android-35.
```

**改动**：安装 SDK 并更新 `app/build.gradle.kts`

```bash
sdkmanager --install "platforms;android-37.2" "build-tools;37.0.0"
```

```kotlin
compileSdk = 37
buildToolsVersion = "37.0.0"
```

> `platforms;android-37` 这个包名**不存在**，实际包名是 `platforms;android-37.2`（含大版本号）。
> 若 `sdkmanager` 报 `Java version 17 or higher is required`，设 `SKIP_JDK_VERSION_CHECK=true` 绕过。

### 2.8 Hilt 2.59 → 2.60.1

**原因**：Kotlin 2.4.20 产出的 metadata 版本是 `2.4.0`，而 Hilt 2.59 内嵌的
`kotlin-metadata-jvm` 最高只支持 `2.3.0`：

```
[Hilt] Provided Metadata instance has version 2.4.0, while maximum supported version is 2.3.0.
```

**改动**：`gradle/libs.versions.toml`

```toml
hilt = "2.60.1"
```

> 同理，**Room 的注解处理器**（`androidx.room:room-compiler`）也有相同的 metadata 版本限制。
> 若 `hiltJavaCompileDebug` 通过后 `kspDebugKotlin` 报同类错误，需同步升 Room。

---

## 3. 刻意保留 minSdk = 24（不移除的说明）

MIUIX 的 `miuix-blur` 模块声明 `minSdk 33`，会让 manifest 合并失败：

```
uses-sdk:minSdkVersion 24 cannot be smaller than version 33
declared in library [top.yukonga.miuix.kmp:miuix-blur-android:0.9.4]
```

**处理**：**移除该依赖**，而不是提高工程的 minSdk。

理由：把 `minSdk` 从 24 提到 33 会**放弃 Android 6.0 ~ 12 的全部用户**，代价远大于收益。
且经全量检索，`miuix-blur` 在本工程中**从未被使用**。

同时移除的还有 `miuix-icons`、`miuix-nav`——同样零引用（图标统一用 `androidx.compose.material.icons`）。

**保留的 MIUIX 依赖**：
```kotlin
implementation(libs.miuix.ui)
implementation(libs.miuix.preference)
```

---

## 4. 仓库镜像配置

`settings.gradle.kts` 中为国内网络加入了阿里云镜像（**置于官方源之前**）：

```kotlin
pluginManagement {
    repositories {
        maven("https://maven.aliyun.com/repository/gradle-plugin")
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/public")
        google { content { ... } }
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositories {
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/public")
        google()
        mavenCentral()
        maven("https://jitpack.io")
        maven("https://oss.sonatype.org/content/repositories/public")
        gradlePluginPortal()
    }
}
```

> **CI 建议**：GitHub Actions 上阿里云镜像会**更慢**（跨境）。
> 如果 CI 变慢，删掉这 5 行 `maven("https://maven.aliyun.com/...")` 即可，
> 官方源 `google()` / `mavenCentral()` 仍在列表中。

---

## 5. 验证状态（重要）

以下结论基于本机实际编译（JDK 22 + Android SDK 37.2 + Gradle 9.6.0）：

| 阶段 | 结果 |
|---|---|
| 插件解析（AGP / KSP / Hilt / protobuf / Compose） | ✅ 通过 |
| **Kotlin 源码编译 `:app:compileDebugKotlin`** | ✅ **BUILD SUCCESSFUL** |
| AAR metadata 检查（compileSdk 37） | ✅ 通过 |
| Manifest 合并（移除 miuix-blur 后） | ✅ 通过 |
| 注解处理 `:app:hiltJavaCompileDebug` | ⚠️ Hilt 已升 2.60.1，**该轮验证被中止，未确认** |

**关键结论**：`:app:compileDebugKotlin` 曾完整 **BUILD SUCCESSFUL**，
意味着 **UI 迁移的全部 Kotlin 代码（87 个文件）已通过编译器检查**。
后续失败均发生在**注解处理 / 打包阶段**，属于构建配置问题，非迁移代码问题。

### 尚未验证的项

1. Hilt 2.60.1 是否解决 metadata 版本问题 → **待编译确认**
2. Room 注解处理器是否也需要升级（同类 metadata 限制）→ **待编译确认**
3. `assembleDebug` 产出 APK → **未完成**
4. 运行时行为 / UI 实际渲染效果 → **完全未验证**

---

## 6. CI 配置参考（GitHub Actions）

```yaml
- uses: actions/setup-java@v4
  with:
    distribution: temurin
    java-version: '22'

- uses: android-actions/setup-android@v3

- name: Install SDK 37.2
  run: sdkmanager --install "platforms;android-37.2" "build-tools;37.0.0"

- name: Build
  run: ./gradlew assembleDebug
```

Gradle 由 wrapper 自动下载（9.6.0），无需额外配置。
