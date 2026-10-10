# MIUIX 组件 API 速查表（改造 c001apk 用，勿再读 Miuix 源码）

包名：`top.yukonga.miuix.kmp.basic.*`（basic）、`top.yukonga.miuix.kmp.preference.*`（preference）、
`top.yukonga.miuix.kmp.overlay.*`（overlay）。

主题访问：`MiuixTheme.colorScheme.*`、`MiuixTheme.textStyles.*`（已全局改好，勿动）。
**重要：不要再去读 Miuix-src 源码，本表已含全部所需签名。**

---

## 1. 可直接换 import 的组件（调用点基本兼容）

### Scaffold —— 完全兼容，只换 import
```kotlin
// MIUIX
Scaffold(
    modifier, topBar, bottomBar, floatingActionButton,
    floatingActionButtonPosition, floatingToolbar, floatingToolbarPosition,
    snackbarHost, popupHost, containerColor, contentWindowInsets,
    content: @Composable (PaddingValues) -> Unit,
)
```
M3 的 `snackbarHost` / `containerColor` / `contentWindowInsets` **都存在**，直接用。
若用了 M3 的 `TopAppBarDefaults`，删掉。

### Surface
```kotlin
Surface(modifier, shape, color, contentColor, border, shadowElevation, content)
Surface(onClick, modifier, enabled, shape, color, contentColor, border, shadowElevation, interactionSource, indication, content)
```
M3 的 `tonalElevation` **不存在** → 删除该参数。其余同名。

### IconButton —— 兼容
```kotlin
IconButton(onClick, modifier, enabled, holdDownState, backgroundColor, cornerRadius, minHeight, minWidth, content)
```

### HorizontalDivider / VerticalDivider —— 兼容
```kotlin
HorizontalDivider(modifier, thickness, color)
VerticalDivider(modifier, thickness, color)
```
M3 的 `Divider` → 用 `HorizontalDivider`。

### FloatingActionButton
```kotlin
FloatingActionButton(onClick, modifier, shape, containerColor, shadowElevation, minWidth, minHeight, content)
```
M3 的 `containerColor`/`shape`/`modifier`/`onClick`/`content` 同名；`contentColor`、`elevation` 不存在 → 删除。

### Switch
```kotlin
Switch(checked, onCheckedChange, modifier, colors, enabled)
```
注意顺序是 `checked` 在前、`onCheckedChange` 第二（M3 也是）。删除 `thumbContent`、`interactionSource`。

### RadioButton
```kotlin
RadioButton(selected, onClick, modifier, colors, enabled)
```
删除 `interactionSource`。

### Slider
```kotlin
Slider(value, onValueChange, modifier, enabled, valueRange, steps, onValueChangeFinished,
       reverseDirection, height, colors, hapticEffect, showKeyPoints, keyPoints, magnetThreshold)
```
删除 `interactionSource`。

### Button
```kotlin
Button(onClick, modifier, enabled, cornerRadius, minWidth, minHeight, colors, insideMargin,
       interactionSource, indication, content: @Composable RowScope.() -> Unit)
```
M3 的 `shape = RoundedCornerShape(x)` → 改成 `cornerRadius = x.dp`。
M3 的 `colors = ButtonDefaults.buttonColors(...)` → 改用 MIUIX 的
`top.yukonga.miuix.kmp.basic.ButtonDefaults.buttonColors(...)` / `buttonColorsPrimary(...)`；
若只是默认色，直接删掉 `colors` 参数最省事。
`elevation`、`border` 不存在 → 删除。

### Card
```kotlin
Card(modifier, cornerRadius, insideMargin, colors, content: @Composable ColumnScope.() -> Unit)
Card(modifier, cornerRadius, insideMargin, colors, pressFeedbackType, showIndication,
     holdDownState, onClick, onLongPress, content)
```
M3 的 `shape = RoundedCornerShape(x)` → `cornerRadius = x.dp`。
M3 的 `colors = CardDefaults.cardColors(...)` → 改成 MIUIX
`top.yukonga.miuix.kmp.basic.CardDefaults.defaultColors(...)`；
`elevation`、`border` 不存在 → 删除。

### ProgressIndicator
```kotlin
LinearProgressIndicator(modifier, progress: Float?, colors, height)   // 注意 progress 是 Float?，不是 lambda
CircularProgressIndicator(modifier, progress: Float?, colors, strokeWidth, size)
```
M3 的 `progress = { 0.5f }`（lambda）→ 改成 `progress = 0.5f`。
若要无限循环（M3 无参形式），用 `InfiniteProgressIndicator(modifier, color, size, strokeWidth, orbitingDotSize)`。

---

## 2. 需要改调用点的组件（结构性差异）

### TopAppBar —— title 是 String，不是 composable！
```kotlin
TopAppBar(title: String, modifier, color, titleColor, largeTitle, largeTitleColor,
          subtitle, subtitleColor, navigationIcon, actions, scrollBehavior,
          defaultWindowInsetsPadding, titlePadding, navigationIconPadding,
          actionIconPadding, bottomContent)
SmallTopAppBar(...)  // 同上，小号
```
改造法：
- `title = { Text("首页") }` → `title = "首页"`（若 title 是 `stringResource(R.string.x)` → `title = stringResource(R.string.x)`）
- 若 title 由变量计算，先 `val titleText = ...` 再 `title = titleText`
- `navigationIcon = { BackButton(...) }` 保持不变（仍是 composable lambda）
- `actions = { ... }` 保持不变
- `colors = TopAppBarDefaults.topAppBarColors(...)` → **删除**
- `scrollBehavior = TopAppBarDefaults.enterAlwaysScrollBehavior(...)` → 若要保留滚动行为，用
  `top.yukonga.miuix.kmp.basic.rememberTopAppBarState()` + `MiuixScrollBehavior(state)`；
  最省事的做法是**删除 scrollBehavior 参数**。
- `windowInsets = ...` → 删除（MIUIX 用 defaultWindowInsetsPadding = true/false）

### TabRow —— 用字符串列表，不要 Tab 子项！
```kotlin
TabRow(tabs: List<String>, selectedTabIndex: Int, onTabSelected: (Int) -> Unit,
       modifier, colors, minWidth, maxWidth, height, cornerRadius, itemSpacing,
       contentAlignment, listState, interactionSource, indication)
TabRowWithContour(...)  // 同样参数
```
改造法（M3 形态）：
```kotlin
// M3
TabRow(selectedTabIndex = i) {
    tabs.forEachIndexed { idx, t -> Tab(selected = i == idx, onClick = { i = idx }, text = { Text(t) }) }
}
// MIUIX
TabRow(tabs = tabs, selectedTabIndex = i, onTabSelected = { i = it }, modifier = ...)
```
`SecondaryTabRow` / `SecondaryScrollableTabRow` → 都用 `TabRow`（横滑用 `TabRowWithContour`）。
删除 `TabRowDefaults`、`Tab` 的 import 与用法。

### DropdownMenu / DropdownMenuItem —— MIUIX 用 Dropdown（preference）
`top.yukonga.miuix.kmp.preference.Dropdown` 的 API 与此差异较大。
**保守做法（推荐）**：本项目 14 处 DropdownMenu 大多只需要「弹出若干可点条目」。
优先尝试 MIUIX `Dropdown`；若签名不确定，**保留 M3 的 DropdownMenu/DropdownMenuItem 不动**
（Material3 依赖仍在工程里，可编译），并在文件顶部加注释 `// TODO miuix: DropdownMenu`。
> 这条是唯一允许保留 M3 的例外，避免因结构差异写坏代码。

### TextButton —— text 是 String 参数，没有 content lambda！
```kotlin
TextButton(text: String, onClick: () -> Unit, modifier, enabled, cornerRadius, minWidth,
           minHeight, colors, insideMargin, textStyle, interactionSource, indication)
```
`TextButton(onClick = {...}) { Text("确定") }` → `TextButton(text = "确定", onClick = {...})`。
若内容不是纯文本（有 Icon 等）→ 改用 `Button`，或保留 M3。

### TextField —— 基于 TextFieldState
```kotlin
TextField(state: TextFieldState, modifier, insideMargin, colors, cornerRadius, label,
          useLabelAsPlaceholder, enabled, readOnly, ..., textStyle, keyboardOptions,
          keyboardActions, leadingIcon, trailingIcon, singleLine, maxLines, minLines,
          visualTransformation, onTextLayout, interactionSource, cursorBrush)
```
M3 的 `value/onValueChange` 形态改成：
```kotlin
val tfState = rememberTextFieldState(initialText = value)
TextField(state = tfState, label = "...", ...)
// 需要回传：LaunchedEffect(tfState.text) { onValueChange(tfState.text.toString()) }
```
若改造风险大（如封装组件 ChatEditText）→ **保留 M3 的 OutlinedTextField/TextField** 并加
`// TODO miuix: TextField` 注释。

### Checkbox —— ToggleableState
```kotlin
Checkbox(state: ToggleableState, onClick: (() -> Unit)?, modifier, colors, enabled)
```
M3 `Checkbox(checked = b, onCheckedChange = {...})` →
`Checkbox(state = if (b) ToggleableState.On else ToggleableState.Off, onClick = {...})`
（`androidx.compose.ui.state.ToggleableState`；三态用 Indeterminate）。

### AlertDialog —— OverlayDialog（overlay 包）
MIUIX 的 `OverlayDialog` 是 Scaffold 宿主式弹窗，API 与 M3 `AlertDialog` 差异大。
**保守做法（推荐）**：若不确定，**保留 M3 AlertDialog 不动**，加 `// TODO miuix: OverlayDialog`。
> 允许保留 M3 的第二个例外。

### SearchBar
```kotlin
SearchBar(inputField: @Composable () -> Unit, onExpandedChange: (Boolean) -> Unit, modifier,
          insideMargin, expanded, outsideEndAction, content: @Composable ColumnScope.() -> Unit)
InputField(query, onQueryChange, onSearch, expanded, onExpandedChange, modifier, label, enabled, ...)
```
M3 SearchBar 形态差异大 → 若改造风险高，**保留 M3 SearchBar**，加 TODO 注释。

### NavigationBar / NavigationBarItem
```kotlin
NavigationBar(modifier, color, showDivider, defaultWindowInsetsPadding, mode, content: @Composable RowScope.() -> Unit)
RowScope.NavigationBarItem(selected, onClick, icon: ImageVector, label: String, modifier, enabled, colors, badge)
```
M3 `NavigationBarItem(selected, onClick, icon = { Icon(...) }, label = { Text("x") })` →
MIUIX `NavigationBarItem(selected = ..., onClick = ..., icon = Icons.Filled.X, label = "x")`
（icon 要传 ImageVector 本体，label 传 String）。

---

## 3. 保持不变（不要动）

- `androidx.compose.material3.Text` —— **保留**
- `androidx.compose.material3.Icon` / `androidx.compose.material.icons.*` —— **保留**
- `androidx.compose.material3.ExperimentalMaterial3Api` —— 若对应组件已迁移，删掉 `@OptIn`；若仍用 M3 组件则保留
- `androidx.compose.material3.pulltorefresh.*` —— **保留**
- `androidx.compose.material3.windowsizeclass.*` —— **保留**
- `MiuixTheme.*` / `MiuixShapes.*` —— 已改好，**不要动**

## 4. 通用要求

- 改完确保：不再有该文件的 `import androidx.compose.material3.<已迁移组件>`；新增正确的 `top.yukonga.miuix.kmp.*` import。
- 保留所有业务逻辑、回调、viewModel 调用。
- 无法安全迁移的组件：保留 M3 + 写 `// TODO miuix: <组件名>` 注释，并在汇报里列出。
