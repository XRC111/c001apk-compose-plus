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

`settings.gradle.kts` 中的阿里云镜像**由环境变量控制**，默认开启：

```kotlin
// 本地默认 true（阿里云，下载快）；CI 设 USE_CN_MIRROR=false 走官方源
if (System.getenv("USE_CN_MIRROR")?.toBooleanStrictOrNull() ?: true) {
    maven("https://maven.aliyun.com/repository/google")
    maven("https://maven.aliyun.com/repository/public")
}
google()
mavenCentral()
```

> **坑（已踩）**：`pluginManagement {}` 是**独立脚本作用域**，
> 无法引用 settings 脚本顶层的 `val` 或 `fun`（会报 `Unresolved reference`）。
> 必须把判断**内联**到 block 内部。

CI 工作流中已设 `USE_CN_MIRROR: 'false'`（GitHub Actions 在国外，走官方源更快）。
wrapper 已恢复官方 `services.gradle.org`。

---

## 5. 验证状态

### 5.1 CI 验证（最终，全部通过）

GitHub Actions `MIUIX Build` 工作流在提交 `4d38205` 上**全绿**：

| 步骤 | 结果 |
|---|---|
| Setup Java 22 | ✅ |
| Install SDK 37.2 / build-tools 37.0.0 | ✅ |
| Setup Gradle | ✅ |
| **Compile Kotlin**（`:app:compileDebugKotlin`） | ✅ |
| **Assemble Debug APK**（`assembleDebug`） | ✅ |
| Upload build artifact | ✅（31 MB APK） |

**这意味着 87 个文件的 UI 迁移代码编译通过，且完整 APK 成功打包。**
Hilt 2.60.1 解决了 metadata 版本问题，Room 无需升级。

### 5.2 本机验证过程（历史）

本机（JDK 22 + Android SDK 37.2 + Gradle 9.6.0）曾跑到 `:app:compileDebugKotlin` BUILD SUCCESSFUL，
随后发现 Hilt metadata 版本问题（已升 2.60.1），最终由 CI 完成完整验证。
后续失败均发生在**注解处理 / 打包阶段**，属于构建配置问题，非迁移代码问题。

### 尚未验证的项

1. 运行时行为 / UI 实际渲染效果 → **完全未验证**（需装机实测）

---

## 6. CI 配置（GitHub Actions）

实际使用的工作流见 `.github/workflows/miuix-build.yml`：

```yaml
env:
  USE_CN_MIRROR: 'false'   # CI 在国外，走官方源

steps:
  - uses: actions/checkout@v4
    with: { fetch-depth: 0 }
  - uses: actions/setup-java@v4
    with: { distribution: temurin, java-version: '22' }
  # 不用 android-actions/setup-android@v3：其 license 步骤在 runner 上必然 exit 1
  - name: Install SDK 37.2 / build-tools 37.0.0
    run: |
      SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
      yes | "$SDKMANAGER" --licenses > /dev/null 2>&1 || true
      "$SDKMANAGER" --install "platforms;android-37.2" "build-tools;37.0.0"
  - uses: gradle/actions/setup-gradle@v4
  - run: chmod +x gradlew
  - run: ./gradlew :app:compileDebugKotlin --stacktrace
  - run: ./gradlew assembleDebug --stacktrace
```

---

## 7. 本机 `git push` 不可用的原因（环境问题，非仓库问题）

本机 **Steam++（Watt Toolkit）** 会把 `github.com` 等 28 个域名写入 hosts 指向 `127.0.0.1`，
由它的本地代理转发。`gh` CLI 能正常走通，但 **git 的 schannel TLS 在此代理上做证书吊销检查会失败**：

```
schannel: next InitializeSecurityContext failed:
CRYPT_E_NO_REVOCATION_CHECK (0x80092012)
```

`git ls-remote` 可以成功（只读、无需认证），但 `git push` 必然失败（exit 128，无错误输出）——
因为 push 需要 `git-receive-pack` 的认证握手，而该握手在本地代理下无法完成。

**可行做法**（择一）：

1. **关闭 Steam++ 后 `git push`**（最简单）
2. **用 `gh api` 走 Git Data API 推送**（本次实际采用）：
   建 blob → 建 tree → 建 commit → PATCH ref。注意 commit message 的 JSON
   必须用 **UTF-8** 写入，否则中文会变成 `?`。
3. 换用 SSH（需配 key；注意本机 22 端口当前也不通）

> 注意：推送时若用 `--force` 覆盖远端，务必确认本地历史正确——
> 本次曾因脚本 bug（PowerShell `HashSet` 默认**大小写不敏感**，
> 把 `androidx.compose.ui.unit.Dp` 和 `.dp` 当成重复项而删掉了后者）
> 产生过一个编译失败的提交，已废弃并重做。
