# MIUIX 迁移映射表 (c001apk-compose → YuKongA/Miuix 0.9.4)

版本基线：Kotlin 2.4.20 / Compose Multiplatform 1.12.1 / AGP 9.4.1
（与 MIUIX 自带 `gradle/libs.versions.toml` 完全一致）

---

## 1. 依赖接线（gradle/libs.versions.toml）

- `miuix = "0.9.4"` → 实际接入 **`miuix-ui` + `miuix-preference`** 两个模块
  （`miuix-icons` / `miuix-nav` / `miuix-blur` 经检索**零引用**，已移除；
  其中 `miuix-blur` 还要求 `minSdk 33`，会阻塞本工程 `minSdk 24`。详见 `BUILD_NOTES.md` §3）
- 核心 compose 坐标切到 `org.jetbrains.compose.*`（1.12.1）：
  ui / ui-graphics / ui-tooling / ui-tooling-preview / ui-test-junit4
- **坑 1（已修）**：`org.jetbrains.compose.material:material-icons-extended` 最高只有 **1.7.3**，
  不存在 1.12.1。已改回 AndroidX：`androidx.compose.material:material-icons-extended:1.7.8`
  （包名仍是 `androidx.compose.material.icons.*`，代码无需改）
- **坑 2（已修）**：`org.jetbrains.compose.ui:ui-test-manifest` **不存在**（404）。
  已改回 `androidx.compose.ui:ui-test-manifest`（版本由 compose BOM 管理）
- **坑 3（已修，最关键）**：Compose BOM 会**降级** Compose UI！
  `composeBom = "2025.10.00"` 把 `androidx.compose.ui:ui` 钉在 **1.9.3**，
  而 MIUIX 0.9.4 需要 **1.12.1** —— BOM 通过 `platform(...)` 生效，会直接压掉 MIUIX 的依赖。
  已改为 `composeBom = "2026.09.00"`，它正好把 ui 钉在 **1.12.1**、material3 钉在 **1.4.0**，
  与 MIUIX 完全对齐（各 BOM 实测值：2025.10.00→ui 1.9.3；
  2026.06.01→1.11.4；2026.08.00→1.12.0；2026.09.00→1.12.1）。
- 关键事实：`org.jetbrains.compose.ui:ui:1.12.1` 在 Android 上只是**别名**，
  实际重定向到 `androidx.compose.ui:ui:1.12.1`（同属 `androidx.compose.ui` atomic group），
  因此与 AndroidX material3 共存**不会重复类**。
- Compose 编译器来自 `org.jetbrains.kotlin.plugin.compose`（version.ref = kotlin = 2.4.20），
  不是 `org.jetbrains.compose` 插件；两者同时 apply（与 MIUIX 一致）。

## 2. 主题层（ui/theme/Theme.kt）

`MaterialTheme` → `MiuixTheme(colors = ..., content = ...)`，配色由 `ThemeController` 生成：
- `materialYou && keyColor == null` → `ThemeController(ColorSchemeMode.MonetSystem)`（系统取色）
- 有 seed → `MonetLight / MonetDark` + `paletteStyle`
- 无 seed → `ColorSchemeMode.Light / Dark`
- 纯黑（AMOLED）：`Colors.toAmoled()` 后处理（把 background/surface 置纯黑并压暗主色）
- 亮度判断改用 `darkTheme: Boolean`（不再自定义 ColorSchemeMode 枚举，避免与 MIUIX 同名冲突）
- 保留：`CompositionLocalProvider(LocalDensity provides Density(...))` 的
  fontScale / contentScale；状态栏/导航栏透明与 `WindowCompat` 明暗图标逻辑。

### 颜色 / 字体 / 形状（已机械替换到 MiuixTheme）
- `MaterialTheme.colorScheme.*` → `MiuixTheme.colorScheme.*`
  - `outlineVariant` → `outline`
  - `surfaceColorAtElevation(e)` → `MiuixTheme.colorScheme.surfaceContainerHigh`
- `MaterialTheme.typography.*` → `MiuixTheme.textStyles.*`，名称按 MIUIX 原生名映射：
  titleLarge→title1, titleMedium→title2, titleSmall→title3,
  bodyLarge→body1, bodyMedium→body1, bodySmall→body2,
  labelLarge→button, labelMedium→footnote1
- `MaterialTheme.shapes.*` → `ui.theme.MiuixShapes.medium / .large`（12.dp / 28.dp）

## 3. 组件迁移结果

### 已迁移到 MIUIX
| 组件 | 数量 | 说明 |
|------|------|------|
| Scaffold | 26 | 直接换 import（参数兼容） |
| TopAppBar | 22 | **title 由 composable 改成 String**；删 TopAppBarDefaults |
| TabRow | 8 | `SecondaryTabRow/SecondaryScrollableTabRow + Tab` → `TabRow(tabs: List<String>, selectedTabIndex, onTabSelected)` |
| Surface | 8 | 删 `tonalElevation` |
| IconButton | 17 | 直接换 import |
| HorizontalDivider | 21 | 直接换 import |
| FloatingActionButton | 5 | 删 `containerColor`/`elevation` 等 M3 专有参数 |
| Card | 4 | ElevatedCard → `Card(cornerRadius = N.dp, colors = CardDefaults.defaultColors(color = ...))` |
| RadioButton | 3 | 删 `interactionSource` |
| Switch / Slider / Button / Checkbox / LinearProgressIndicator | 各 1~2 | `progress = { x }` lambda → `progress = x` |
| TextButton | 9 | **`text` 是 String 参数，没有 content lambda**（纯文本场景）；内容含 Icon 的场景改用 `Button` |
| Button | 4 | 由含图标的 `TextButton` 转换而来（`Button` 接受 content lambda） |
| DropdownEntry / DropdownItem | 各 14 | 下拉菜单体系（见下） |
| Badge / BadgedBox | 4 | 签名与 M3 一致，仅换 import |
| BasicComponent | 4 | 列表项（覆盖 25+ 调用点，替代 `ListItem` + 自定义列表封装） |
| OverlayDialog | 10 | M3 AlertDialog → `OverlayDialog(show, title: String, onDismissRequest) { Row { TextButton... } }` |
| OverlayBottomSheet | 2 | M3 ModalBottomSheet → `OverlayBottomSheet(show = true, onDismissRequest, modifier)` |
| OverlayIconDropdownMenu | 18 | M3 `DropdownMenu` → `OverlayIconDropdownMenu(entries = listOf(DropdownEntry(items = buildList { ... })))`（自带 IconButton 与展开状态） |
| OverlayIconCascadingDropdownMenu | 2 | 嵌套/级联菜单（`DropdownItem.children` 表达子菜单、`selected` 表达选中态，替代手写 `Row + RadioButton`） |
| OverlayDropdownPopup | 1 | 长按上下文菜单（`onDismissFinished`/`maxHeight`/`dropdownColors`/`renderInRootScaffold` 均**无默认值**，必须显式传） |

> **菜单迁移的关键决策**：MIUIX 的 `OverlayIconDropdownMenu` 自带 IconButton 并**内部管理展开状态**，
> 因此迁移后 `dropdownMenuExpanded` 状态、`MoreMenuButton`、`Box { }` 包裹全部删除。
> 条件项（`if (isLogin)` 等）统一用 `buildList { }` 表达；
> 索引→动作的 `when (index)` 映射展开为每个 `DropdownItem` 直接携带 `onClick`，消除 `else` 死分支。

### 有意保留 Material3（无对应或改造风险高）
| 组件 | 数量 | 原因 |
|------|------|------|
| Text / Icon | 63 / 32 | 保留（MIUIX 也有，但 M3 版本行为一致，无需改） |
| pulltorefresh | 18 | AndroidX 专有，MIUIX 无对等物 |
| windowsizeclass | 4 | MIUIX 无对等物 |
| FilledTonalButton | 5 | 与 MIUIX `Button` **视觉语义不同**（填充色调 vs 标准填充），机械替换会改变外观 |
| TextField / OutlinedTextField | 5+2 | MIUIX 基于 `TextFieldState`，需重构状态模型（非机械替换） |
| TopAppBar | 3 | title 里放的是 `TextField`（搜索框），MIUIX 的 title **只接受 String**——架构性不兼容 |
| OutlinedButton | 3 | 描边视觉与 MIUIX `Button` 填充色调语义不同 |

## 4. 已修复的迁移陷阱（重要）

1. **`windowInsets` 参数不存在于 MIUIX TopAppBar**（用 `defaultWindowInsetsPadding`）——
   15 处已删除；删除时留下的 17 处孤儿 `.only(...)` 片段也已清理。
2. **`ScaffoldDefaults.contentWindowInsets` 是 M3 概念** —— 2 处改为
   `WindowInsets.systemBars.union(WindowInsets.displayCutout)`。
3. **`tonalElevation` 不存在于 MIUIX Surface** —— 1 处已删。
4. **MIUIX Checkbox 需要 `state: ToggleableState`**（不是 `checked`/`onCheckedChange`）。
   HomeScreen 的板块选择项后来整体迁移为 `BasicComponent`，`canToggle` 直接映射到 `enabled`。
5. **MIUIX `TopAppBar` 的 title 是 `String`，不接受 composable** ——
   这是 3 处搜索框 TopAppBar 无法迁移的**根因**。
6. **`org.jetbrains.compose.material:material-icons-extended` 没有 1.12.1**
   （最高 1.7.3）→ 已改用 `androidx.compose.material:material-icons-extended:1.7.8`。
7. **`org.jetbrains.compose.ui:ui-test-manifest` 不存在（404）**
   → 已改回 `androidx.compose.ui:ui-test-manifest`。
8. **`MiuixTheme.colorScheme.onSurfaceVariant` 不存在** —— MIUIX 的 `Colors` 用的是
   `onSurfaceVariantSummary`（次要文字）与 `onSurfaceVariantActions`（可交互元素）。
   18 处已改为 `onSurfaceVariantSummary`。**这是编译器才抓得到的错误**（见 §5.3）。
9. **MIUIX `CircularProgressIndicator` 没有 `strokeCap` 参数**（2 处已删）。
10. **`OverlayIconDropdownMenu` 自带 IconButton 且内部管理展开状态** ——
    迁移后必须删除原有的 `MoreMenuButton`、`Box {}` 包裹和 `dropdownMenuExpanded` 状态，
    否则会出现"两个按钮"或状态双份。
11. **MIUIX 的 overlay 组件默认 `renderInRootScaffold = true`**，需要一个 MIUIX `Scaffold` 祖先。
    若宿主是第三方 Scaffold（如 `CollapsingToolbarScaffold`），需传 `renderInRootScaffold = false`。

## 5. 验证结果

### 5.1 静态检查

- `MaterialTheme` 残留引用：**0**
- `MiuixTheme` 使用但缺 import：**0**
- MIUIX 组件调用点非法参数（brace-aware 校验）：**0**
- 花括号/圆括号不平衡文件：**0**
- 同一简单名同时从 M3 与 MIUIX 导入（重名冲突）：**0**
- MIUIX import 符号可解析性：**35/35**
- 变更规模：87 个文件修改

### 5.2 真实编译验证（关键）

已在本机跑通真实编译（JDK 22 + Android SDK 37.2 + Gradle 9.6.0）：

| 阶段 | 结果 |
|---|---|
| 插件解析（AGP 9.4.1 / KSP / Hilt / protobuf / Compose） | ✅ 通过 |
| **`:app:compileDebugKotlin`** | ✅ **BUILD SUCCESSFUL** |
| AAR metadata 检查 | ✅ 通过 |
| Manifest 合并 | ✅ 通过 |
| `:app:hiltJavaCompileDebug` | ⚠️ 未确认（验证被中止） |

> **`:app:compileDebugKotlin` 曾完整 BUILD SUCCESSFUL**，
> 说明 **UI 迁移的全部 Kotlin 代码已通过编译器检查**。

### 5.3 编译器抓出的迁移错误（静态检查无法发现，均已修复）

真实编译暴露了以下**只有编译器能发现**的问题，共 5 类：

| 错误 | 处数 | 修复 |
|---|---|---|
| `MiuixTheme.colorScheme.onSurfaceVariant` 不存在 | **18** | → `onSurfaceVariantSummary`（MIUIX `Colors` 无 `onSurfaceVariant` 字段） |
| `navigationIconnavigationIcon` 参数名重复拼接 | 2 | 删除 `windowInsets` 时的正则残留 |
| `strokeCap` 参数不存在 | 2 | MIUIX `CircularProgressIndicator` 无此参数，删除 |
| `Editable.getChars` 无法解析 | 2 | SDK 37 把 `getChars` 移到 `GetChars` 接口 → 改用 `subSequence()` |
| M3 `ButtonColors` 传给 MIUIX `Button` | 1 | `ButtonDefaults` 换成 MIUIX 版 |

另有 `scrollBehavior` 残留引用、缺失的 `Icon`/`Icons`/`MoreVert` import、
`Theme.kt` 误删的 `dp` import、`IllegalArgumentException` 语法错误等，均已修复。

> **教训**：`onSurfaceVariant` 那 18 处是机械替换的典型陷阱——
> `MaterialTheme.colorScheme.onSurfaceVariant` 改成 `MiuixTheme.colorScheme.onSurfaceVariant`
> 语法上完全合理，静态检查（符号存在性、括号平衡）**全部通过**，
> 只有编译器知道 MIUIX 的 `Colors` 根本没有这个字段。

## 6. 构建配置改动

升级到 MIUIX 官方版本矩阵需要 8 项构建配置改动（AGP 9 破坏性变更 + 依赖版本），
**完整说明见 [`BUILD_NOTES.md`](./BUILD_NOTES.md)**。要点：

- Gradle 9.1.0 → **9.6.0**（AGP 9.4.1 强制要求）
- KSP `2.4.20-2.0.2`（**不存在**）→ **2.3.12**
- 移除 `org.jetbrains.kotlin.android`（AGP 9 内置 Kotlin）
- `packagingOptions` → `packaging`；移除 `applicationVariants`
- protobuf 插件 `0.9.6` → **0.10.0**（0.9.6 与 AGP 9 不兼容）
- compileSdk 35 → **37**（MIUIX 0.9.4 AAR metadata 要求）
- Hilt 2.59 → **2.60.1**（Kotlin 2.4.20 metadata 版本限制）
- 移除 `miuix-blur` / `miuix-icons` / `miuix-nav`（零引用，且 blur 要求 minSdk 33）

## 7. 已知版本仲裁风险（保留项相关）

MIUIX 传递依赖 `org.jetbrains.compose.material3:material3-window-size-class-android:1.12.0-alpha03`，
而它是个**别名 POM**，实际指向 `androidx.compose.material3:material3-window-size-class-android:1.5.0-alpha22`，
后者又依赖 `androidx.compose.material3:material3:1.5.0-alpha22`。

后果：
- **不会重复类**（同一 `groupId:artifactId`，Gradle 只做版本仲裁）。
- 但 `material3` 会被仲裁到 **1.5.0-alpha22（alpha）**，覆盖 BOM 2026.09.00 里
  Google 测过的 `material3 1.4.0 + ui 1.12.1` 稳定组合。

实测：`:app:compileDebugKotlin` 在此仲裁下**编译通过**，说明暂不需要 `force`。
若后续出现 M3 相关报错，两种处理方式（择一）：

1. **强制对齐到稳定版**——在 `app/build.gradle.kts` 末尾加：
   ```kotlin
   configurations.configureEach {
       resolutionStrategy {
           force("androidx.compose.material3:material3:1.4.0")
           force("androidx.compose.material3:material3-window-size-class-android:1.4.0")
           force("androidx.compose.material3:material3-adaptive-navigation-suite:1.4.0")
       }
   }
   ```
2. **跟随 alpha**——不做处理，接受 `material3 1.5.0-alpha22`。

排查命令：`./gradlew :app:dependencies --configuration debugRuntimeClasspath | findstr material3`

## 8. 尚未完成的验证

1. Hilt 2.60.1 是否解决 metadata 版本问题 → 待编译确认
2. Room 注解处理器是否也需升级（同类 metadata 限制）→ 待编译确认
3. `assembleDebug` 产出 APK → 未完成
4. **运行时行为 / UI 实际渲染效果 → 完全未验证**

## 9. 有意保留 Material3 的组件

| 组件 | 处数 | 保留原因 |
|---|---|---|
| `Text` / `Icon` | 95 | 行为一致，无迁移必要 |
| `pulltorefresh` | 18 | MIUIX 无对等物 |
| `FilledTonalButton` | 5 | 与 MIUIX `Button` 视觉语义不同，机械替换会改变外观 |
| `TextField` / `OutlinedTextField` | 5+2 | MIUIX 基于 `TextFieldState`，需重构状态模型 |
| `windowsizeclass` | 4 | MIUIX 无对等物 |
| `TopAppBar`（内嵌搜索框） | 3 | MIUIX `title` 只接受 String，**架构性不兼容** |
| `OutlinedButton` | 3 | 描边视觉与 MIUIX `Button` 填充色调语义不同 |

