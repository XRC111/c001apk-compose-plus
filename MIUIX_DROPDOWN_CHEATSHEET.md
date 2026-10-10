# MIUIX Dropdown API 速查（DropdownMenu 迁移用，勿读 Miuix 源码）

## 目标：把 M3 DropdownMenu 换成 MIUIX 等价物

### 导入
```kotlin
import top.yukonga.miuix.kmp.menu.OverlayIconDropdownMenu
import top.yukonga.miuix.kmp.basic.DropdownEntry
import top.yukonga.miuix.kmp.basic.DropdownItem
```
（若原来用 `OverlayDropdownMenu` 形态，导入 `top.yukonga.miuix.kmp.menu.OverlayDropdownMenu`）

### API
```kotlin
@Composable
fun OverlayIconDropdownMenu(
    entries: List<DropdownEntry>,          // 必填：菜单分组
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    maxHeight: Dp? = null,
    dropdownColors: DropdownColors = DropdownDefaults.dropdownColors(),
    renderInRootScaffold: Boolean = true,
    collapseOnSelection: Boolean = entries.size <= 1,
    onExpandedChange: ((Boolean) -> Unit)? = null,
    backgroundColor: Color = Color.Unspecified,
    cornerRadius: Dp = IconButtonDefaults.CornerRadius,
    minHeight: Dp = IconButtonDefaults.MinHeight,
    minWidth: Dp = IconButtonDefaults.MinWidth,
    content: @Composable () -> Unit,       // 必填：按钮内容（通常放 Icon）
)

data class DropdownEntry(
    val items: List<DropdownItem>,
    val enabled: Boolean = true,
)

data class DropdownItem(
    val text: String,                      // 必填
    val enabled: Boolean = true,
    val selected: Boolean = false,         // 选中态（替代原来的 background 高亮）
    val onClick: (() -> Unit)? = null,
    val icon: @Composable ((Modifier) -> Unit)? = null,
    val summary: String? = null,
    val children: List<DropdownItem>? = null,   // 子菜单
)
```

> 注意：`OverlayIconDropdownMenu` **自带 IconButton**，内部管理展开状态。
> 不要再外包裹 `Box { MoreMenuButton {...}; DropdownMenu(...) }`。

## 标准改写

### 原 M3 形态
```kotlin
var dropdownMenuExpanded by remember { mutableStateOf(false) }

Box {
    MoreMenuButton { dropdownMenuExpanded = true }
    DropdownMenu(
        expanded = dropdownMenuExpanded,
        onDismissRequest = { dropdownMenuExpanded = false }
    ) {
        DropdownMenuItem(
            text = { Text("复制") },
            onClick = {
                dropdownMenuExpanded = false
                context.copyText(...)
            }
        )
        DropdownMenuItem(
            text = { Text("分享") },
            onClick = {
                dropdownMenuExpanded = false
                context.shareText(...)
            }
        )
    }
}
```

### 改成 MIUIX
```kotlin
OverlayIconDropdownMenu(
    entries = listOf(
        DropdownEntry(
            items = listOf(
                DropdownItem(
                    text = "复制",
                    onClick = { context.copyText(...) },
                ),
                DropdownItem(
                    text = "分享",
                    onClick = { context.shareText(...) },
                ),
            )
        )
    ),
) {
    Icon(
        imageVector = Icons.Default.MoreVert,
        contentDescription = null,
    )
}
```

## 改写要点

1. **删掉 `dropdownMenuExpanded` 状态变量**（MIUIX 内部管理）。
   若该变量还有别的用途（例如别处读取），则保留变量并配合 `onExpandedChange` 同步：
   ```kotlin
   OverlayIconDropdownMenu(
       entries = ...,
       onExpandedChange = { dropdownMenuExpanded = it },
   ) { Icon(...) }
   ```
2. **`text = { Text("x") }` → `text = "x"`**（String，不是 composable）。
   若是 `stringResource(...)`，直接 `text = stringResource(...)`。
   若 text 里有动态拼接/多行 Text，先算成 `val t = ...` 再传。
3. **`onClick` 里删掉 `dropdownMenuExpanded = false`**（MIUIX 自动收起，
   `collapseOnSelection` 默认 true）。
4. **原来用 `Modifier.background(if (selected) ... else ...)` 表示选中** →
   改成 `selected = true/false` 参数。
5. **`MoreMenuButton { ... }` 调用 → 换成 `Icon(Icons.Default.MoreVert, contentDescription = null)`**
   作为尾随 lambda 内容；外层的 `Box { }` 如果只用来装按钮+菜单，可以整个删掉
   （`OverlayIconDropdownMenu` 自带 Box）。
   注意：`MoreMenuButton` 定义在 `com.example.c001apk.compose.ui.component.Haptic.kt`，
   它内部包了震动反馈；MIUIX 版本自带 ContextClick 震动，所以可以放心替换。
6. 若菜单项里有 `leadingIcon = { Icon(...) }`（M3 参数）→ 改用 `icon = { Icon(...) }`，
   注意 MIUIX 的 icon lambda 接收一个 `Modifier` 参数：
   ```kotlin
   DropdownItem(
       text = "编辑",
       icon = { m -> Icon(Icons.Default.Edit, contentDescription = null, modifier = m) },
       onClick = { ... },
   )
   ```
   若改造麻烦，直接省略 icon 参数（视觉降级可接受）。
7. `DropdownMenuItem` 的 `trailingIcon`、`contentPadding` 等 MIUIX 没有 → 删除。
8. 保留所有业务逻辑（onClick 里的实际操作）。

## 不要动

- `androidx.compose.material3.Icon` / `Icons.*` —— 保留
- `androidx.compose.material3.Text` —— 保留（除非已迁移）
- `MiuixTheme.*` / `MiuixShapes.*` —— 已改好
- 若某个 DropdownMenu 结构特殊（例如菜单内容是**动态列表 + 复杂布局**、
  或菜单不在 Scaffold 内导致 overlay 无法渲染），**保留 M3 并加
  `// TODO miuix: DropdownMenu` 注释**，在汇报里列出。

## 收尾
- 确保文件里不再有 `import androidx.compose.material3.DropdownMenu` /
  `DropdownMenuItem`（除非该文件仍有保留的 M3 菜单）。
- 确保新增正确的 MIUIX import。
- 保证花括号/圆括号平衡。
