# MD3 Layout and Responsive Design — Compose / KMP

Reference for Material Design 3's layout system in **Jetpack Compose** and
**Compose Multiplatform**: window size classes, adaptive scaffolds, canonical layouts.

---

## Google I/O 2026: Expressive Layout

- **Expressive layout scaffold**: Design screens to adapt across mobile, desktop, foldables.
  In Compose, prefer Material3 adaptive scaffold APIs over hardcoded phone-first layouts.
- **8dp spacing system**: Define spacing as tokens — never scatter raw `Dp` literals.
- **Foldable support**: Use `WindowInfoTracker` / `FoldingFeature` (Jetpack WindowManager).
- **Desktop**: Use `NavigationRail` or permanent `NavigationDrawer`; no bottom nav bar.

---

## Window Size Classes

MD3 defines 5 breakpoint classes. In Compose, use `calculateWindowSizeClass()` (or
`currentWindowAdaptiveInfo()` in Material3 Adaptive) — never hand-roll raw width checks.

| Class | Width Range | Typical Devices | Columns |
|---|---|---|---|
| Compact | < 600dp | Phone portrait | 4 |
| Medium | 600–839dp | Tablet portrait, foldable | 8 |
| Expanded | 840–1199dp | Tablet landscape, small desktop | 12 |
| Large | 1200–1599dp | Desktop | 12 |
| Extra-large | 1600dp+ | Ultra-wide, large desktop | 12 |

### Using WindowSizeClass in Compose

```kotlin
// androidMain — Activity
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val windowSizeClass = calculateWindowSizeClass(this)
            AppTheme {
                App(windowSizeClass = windowSizeClass)
            }
        }
    }
}

// commonMain — App.kt
@Composable
fun App(windowSizeClass: WindowSizeClass) {
    when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact  -> CompactLayout()
        WindowWidthSizeClass.Medium   -> MediumLayout()
        WindowWidthSizeClass.Expanded -> ExpandedLayout()
        else                          -> ExpandedLayout()
    }
}
```

### Material3 Adaptive API (recommended for newer projects)

```kotlin
// Requires: androidx.compose.material3.adaptive:adaptive
@Composable
fun AdaptiveApp() {
    val adaptiveInfo = currentWindowAdaptiveInfo()
    val windowSizeClass = adaptiveInfo.windowSizeClass

    // Use NavigableListDetailPaneScaffold for list-detail layouts
    val navigator = rememberListDetailPaneScaffoldNavigator<Any>()

    BackHandler(navigator.canNavigateBack()) { navigator.navigateBack() }

    NavigableListDetailPaneScaffold(
        navigator    = navigator,
        listPane     = {
            AnimatedPane {
                ItemListPane(onItemSelected = { item ->
                    navigator.navigateTo(ListDetailPaneScaffoldRole.Detail, item)
                })
            }
        },
        detailPane   = {
            val item = navigator.currentDestination?.content
            AnimatedPane {
                if (item != null) ItemDetailPane(item)
                else EmptyDetailPane()
            }
        }
    )
}
```

---

## Layout Anatomy

| Term | Definition |
|---|---|
| Window | The visible area of the app |
| Pane | A layout container within the window (fixed, flexible, floating, semi-permanent) |
| Column | A vertical content block within a pane |
| Margin | Space between screen edge and content |
| Gutter | Space between columns |
| Spacer | Space between panes in multi-pane layouts |

### Margin and Gutter Values

| Window Size | Screen Margin | Gutter |
|---|---|---|
| Compact | 16dp | 8dp |
| Medium | 24dp | 16dp |
| Expanded | 24dp | 16dp |
| Large | 24dp | 24dp |
| Extra-large | 24dp | 24dp |

---

## Spacing Token Pattern

Define once in `Dimens.kt`, use everywhere:

```kotlin
// theme/Dimens.kt
object Dimens {
    val xxs = 4.dp    // icon padding, tight gaps
    val xs  = 8.dp    // between related elements
    val sm  = 12.dp   // small internal padding
    val md  = 16.dp   // standard screen padding
    val lg  = 24.dp   // section gaps
    val xl  = 32.dp   // major separators
    val xxl = 48.dp   // hero spacing

    val screenHorizontal = 16.dp  // compact screen margin
    val screenVertical   = 16.dp

    val screenHorizontalExpanded = 24.dp  // expanded screen margin
}
```

**Use spacing tokens for:**
- Screen margins (`contentPadding` in `LazyColumn`, `Modifier.padding`)
- Card internal padding
- Between list items
- Component groups and toolbars
- Pane gaps in multi-pane layouts

---

## Canonical Layouts

MD3 defines 3 canonical layouts. Always start from one of these.

### 1. Feed Layout

**Use when**: Displaying a large browsable collection (social feed, news, product grid).

```
Compact:   Single column of cards
Medium:    2-column grid
Expanded:  3-column grid
Large:     4-column grid + optional side panel
```

```kotlin
@Composable
fun FeedLayout(
    items: List<ItemModel>,
    windowSizeClass: WindowSizeClass
) {
    val columns = when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact  -> 1
        WindowWidthSizeClass.Medium   -> 2
        WindowWidthSizeClass.Expanded -> 3
        else                          -> 4
    }
    val padding = when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact  -> PaddingValues(Dimens.md)
        else                          -> PaddingValues(Dimens.lg)
    }
    val gap = when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact  -> Dimens.xs
        else                          -> Dimens.md
    }

    LazyVerticalGrid(
        columns             = GridCells.Fixed(columns),
        contentPadding      = padding,
        horizontalArrangement = Arrangement.spacedBy(gap),
        verticalArrangement   = Arrangement.spacedBy(gap)
    ) {
        items(items) { item ->
            ItemCard(item)
        }
    }
}
```

---

### 2. List-Detail Layout

**Use when**: Browsing a list where each item has rich detail (email, contacts, file browser).

```
Compact:   List view OR detail view — navigate between them
Medium:    List (1/3) + detail (2/3) side-by-side
Expanded:  Side-by-side with wider detail pane
```

```kotlin
// Using Material3 Adaptive ListDetailPaneScaffold (recommended)
@Composable
fun ListDetailLayout() {
    val navigator = rememberListDetailPaneScaffoldNavigator<String>()

    BackHandler(navigator.canNavigateBack()) { navigator.navigateBack() }

    NavigableListDetailPaneScaffold(
        navigator  = navigator,
        listPane   = {
            AnimatedPane {
                LazyColumn {
                    items(items) { item ->
                        ListItem(
                            headlineContent = { Text(item.title) },
                            modifier        = Modifier.clickable {
                                navigator.navigateTo(ListDetailPaneScaffoldRole.Detail, item.id)
                            }
                        )
                    }
                }
            }
        },
        detailPane = {
            val itemId = navigator.currentDestination?.content
            AnimatedPane {
                if (itemId != null) {
                    DetailPane(itemId = itemId)
                } else {
                    EmptyPane()
                }
            }
        }
    )
}

// Manual implementation without Adaptive API
@Composable
fun ManualListDetail(
    windowSizeClass: WindowSizeClass,
    selectedItem: ItemModel?,
    onItemSelected: (ItemModel) -> Unit,
    onNavigateBack: () -> Unit
) {
    val isExpanded = windowSizeClass.widthSizeClass != WindowWidthSizeClass.Compact

    if (isExpanded) {
        // Side-by-side on medium/expanded
        Row(modifier = Modifier.fillMaxSize()) {
            ItemList(
                modifier    = Modifier.width(360.dp),
                onItemClick = onItemSelected
            )
            HorizontalDivider(modifier = Modifier.fillMaxHeight().width(1.dp))
            ItemDetail(
                modifier = Modifier.weight(1f),
                item     = selectedItem
            )
        }
    } else {
        // Stacked on compact — navigate between panes
        if (selectedItem != null) {
            ItemDetail(item = selectedItem, onBack = onNavigateBack)
        } else {
            ItemList(onItemClick = onItemSelected)
        }
    }
}
```

---

### 3. Supporting Pane Layout

**Use when**: A primary task has supplementary context (composer + preview, editor + properties).

```
Compact:   Modal bottom sheet for the supporting pane
Medium:    Bottom sheet or side sheet
Expanded:  Permanent side-by-side supporting pane
```

```kotlin
@Composable
fun SupportingPaneLayout(windowSizeClass: WindowSizeClass) {
    val isExpanded = windowSizeClass.widthSizeClass == WindowWidthSizeClass.Expanded

    if (isExpanded) {
        Row(modifier = Modifier.fillMaxSize()) {
            PrimaryContent(modifier = Modifier.weight(1f))
            Spacer(Modifier.width(Dimens.md))
            SupportingPane(
                modifier = Modifier.width(360.dp)
            )
        }
    } else {
        var showSheet by remember { mutableStateOf(false) }

        Box(modifier = Modifier.fillMaxSize()) {
            PrimaryContent(modifier = Modifier.fillMaxSize())
            if (showSheet) {
                ModalBottomSheet(onDismissRequest = { showSheet = false }) {
                    SupportingPane()
                }
            }
        }
    }
}
```

---

## Edge-to-Edge and WindowInsets

Always call `enableEdgeToEdge()` in Android Activity. Apply insets properly:

```kotlin
// Scaffold handles most cases automatically
Scaffold(modifier = Modifier.fillMaxSize()) { contentPadding ->
    // contentPadding already accounts for status bar, nav bar, and IME
    LazyColumn(contentPadding = contentPadding) { }
}

// For non-Scaffold screens
Box(
    modifier = Modifier
        .fillMaxSize()
        .statusBarsPadding()
        .navigationBarsPadding()
        .imePadding()  // keyboard avoidance
) { }

// Specific insets
Box(modifier = Modifier.windowInsetsPadding(WindowInsets.safeContent)) { }
```

---

## Foldable Support

```kotlin
// Requires: androidx.window:window
@Composable
fun FoldableAwareLayout() {
    val activity = LocalContext.current as ComponentActivity
    val windowInfo = WindowInfoTracker.getOrCreate(activity).windowLayoutInfo(activity)
        .collectAsStateWithLifecycle(initialValue = null)

    val foldingFeature = windowInfo.value?.displayFeatures
        ?.filterIsInstance<FoldingFeature>()
        ?.firstOrNull()

    val isTableTop = foldingFeature?.orientation == FoldingFeature.Orientation.HORIZONTAL
    val isBook     = foldingFeature?.orientation == FoldingFeature.Orientation.VERTICAL

    when {
        isTableTop -> TableTopLayout()
        isBook     -> BookLayout()
        else       -> DefaultLayout()
    }
}
```

---

## Adaptive Navigation Example

Full adaptive navigation (Compact → Medium → Expanded):

```kotlin
@Composable
fun AdaptiveNavigationScaffold(
    navController: NavHostController,
    windowSizeClass: WindowSizeClass,
    destinations: List<TopLevelDestination>,
    content: @Composable (PaddingValues) -> Unit
) {
    val isCompact  = windowSizeClass.widthSizeClass == WindowWidthSizeClass.Compact
    val isMedium   = windowSizeClass.widthSizeClass == WindowWidthSizeClass.Medium
    val isExpanded = windowSizeClass.widthSizeClass == WindowWidthSizeClass.Expanded

    if (isCompact) {
        // Bottom nav bar
        Scaffold(
            bottomBar = {
                NavigationBar {
                    destinations.forEach { dest ->
                        NavigationBarItem(
                            selected = /* currentRoute */ false,
                            onClick  = { navController.navigate(dest.route) },
                            icon     = { Icon(dest.icon, dest.label) },
                            label    = { Text(dest.label) }
                        )
                    }
                }
            },
            content = content
        )
    } else {
        // Navigation rail (medium) or permanent drawer (expanded)
        Row(modifier = Modifier.fillMaxSize()) {
            if (isMedium) {
                NavigationRail {
                    Spacer(Modifier.weight(1f))
                    destinations.forEach { dest ->
                        NavigationRailItem(
                            selected = false,
                            onClick  = { navController.navigate(dest.route) },
                            icon     = { Icon(dest.icon, null) },
                            label    = { Text(dest.label) }
                        )
                    }
                    Spacer(Modifier.weight(1f))
                }
            } else {
                PermanentNavigationDrawer(
                    drawerContent = {
                        PermanentDrawerSheet {
                            destinations.forEach { dest ->
                                NavigationDrawerItem(
                                    label    = { Text(dest.label) },
                                    icon     = { Icon(dest.icon, null) },
                                    selected = false,
                                    onClick  = { navController.navigate(dest.route) }
                                )
                            }
                        }
                    }
                ) { }
            }

            Scaffold(content = content)
        }
    }
}
```

---

## Rules

- **Never** hardcode breakpoints as raw `Dp` widths — use `WindowSizeClass`
- **Never** scatter raw spacing `Dp` values in reusable UI — use `Dimens` object
- **Always** call `enableEdgeToEdge()` and handle `WindowInsets` on Android
- **Desktop** (`jvmMain`): no `WindowSizeClass` API — use Compose window size via `LocalWindowInfo`
- Bottom navigation bar is **Compact only** — use `NavigationRail` on medium, drawer on expanded
- Use `NavigableListDetailPaneScaffold` from `material3-adaptive` for list-detail — don't re-invent it

---

## Dependency

```toml
[versions]
material3Adaptive    = "1.1.0"
composeMultiplatform = "1.8.2"

[libraries]
# Compose Material3 — explicit declaration (compose.* accessors deprecated in CMP 1.10)
compose-material3          = { module = "org.jetbrains.compose.material3:material3",            version.ref = "composeMultiplatform" }
compose-material-icons-core = { module = "org.jetbrains.compose.material:material-icons-core", version.ref = "composeMultiplatform" }

# Adaptive — use JetBrains-published multiplatform adaptive artifacts
material3-adaptive        = { module = "org.jetbrains.compose.material3.adaptive:adaptive",          version.ref = "composeMultiplatform" }
material3-adaptive-layout = { module = "org.jetbrains.compose.material3.adaptive:adaptive-layout",  version.ref = "composeMultiplatform" }
material3-adaptive-nav    = { module = "org.jetbrains.compose.material3.adaptive:adaptive-navigation", version.ref = "composeMultiplatform" }

# Window size class is bundled with material3 in CMP 1.8+ — no separate dep needed
# If targeting Android-only, you can use:
# window-size-class = { module = "androidx.compose.material3:material3-window-size-class", version = "1.3.1" }
```

---

## Official Docs

- [Adaptive Layouts](https://developer.android.com/develop/ui/compose/layouts/adaptive)
- [WindowSizeClass](https://developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes)
- [Material3 Adaptive](https://developer.android.com/jetpack/androidx/releases/compose-material3-adaptive)
- [Edge-to-Edge](https://developer.android.com/develop/ui/compose/layouts/insets)
- [Foldables](https://developer.android.com/develop/ui/compose/layouts/adaptive/support-different-screen-sizes)
