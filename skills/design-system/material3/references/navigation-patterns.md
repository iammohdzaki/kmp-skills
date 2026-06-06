# MD3 Navigation Patterns — Compose / KMP

Guide for choosing and implementing Material Design 3 navigation in **Jetpack Compose**
and **Compose Multiplatform**.

---

## Navigation Component Selection

### Decision Tree

```
How many primary destinations?

2 destinations
└── Tabs (top, below app bar)

3–5 destinations
├── Compact  (< 600dp)     → Navigation Bar (bottom)
├── Medium   (600–839dp)   → Navigation Rail (side)
└── Expanded (≥ 840dp)     → Navigation Drawer (permanent side)

6+ destinations
├── Compact   → Modal Navigation Drawer
├── Medium    → Standard Drawer or Rail + overflow
└── Expanded  → Permanent Navigation Drawer

Hierarchical (nested sections)
└── Navigation Drawer with sections/groups
```

### Quick Reference

| Component | Destinations | Screen Size | Persistence | Position |
|---|---|---|---|---|
| Navigation Bar | 3–5 | Compact | Persistent | Bottom |
| Navigation Rail | 3–7 | Medium | Persistent | Side (start) |
| Navigation Drawer (permanent) | Unlimited | Expanded+ | Always visible | Side (start) |
| Navigation Drawer (modal) | Unlimited | Compact/Medium | Drawer opens | Side (start) |
| Tabs | 2+ related views | Any | Persistent | Top (below app bar) |
| Bottom App Bar | Contextual actions | Compact | Persistent | Bottom |

---

## Navigation Bar (Compact / Bottom)

**Use when**: 3–5 primary destinations on phone-sized screens.

```kotlin
// Define destinations
data class TopLevelDest(
    val route: Any,       // @Serializable route object
    val icon: ImageVector,
    val label: String
)

val destinations = listOf(
    TopLevelDest(HomeRoute,     Icons.Default.Home,         "Home"),
    TopLevelDest(SearchRoute,   Icons.Default.Search,       "Search"),
    TopLevelDest(ProfileRoute,  Icons.Default.Person,       "Profile"),
)

// In Scaffold
Scaffold(
    bottomBar = {
        NavigationBar {
            val navBackStackEntry by navController.currentBackStackEntryAsState()
            val currentDest = navBackStackEntry?.destination

            destinations.forEach { dest ->
                val selected = currentDest?.hierarchy?.any {
                    it.hasRoute(dest.route::class)
                } == true

                NavigationBarItem(
                    selected       = selected,
                    onClick        = {
                        navController.navigate(dest.route) {
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            launchSingleTop = true
                            restoreState    = true
                        }
                    },
                    icon  = { Icon(dest.icon, contentDescription = dest.label) },
                    label = { Text(dest.label) },
                    alwaysShowLabel = true
                )
            }
        }
    }
) { contentPadding ->
    NavHost(navController, startDestination = HomeRoute, modifier = Modifier.padding(contentPadding)) {
        composable<HomeRoute>    { HomeScreen() }
        composable<SearchRoute>  { SearchScreen() }
        composable<ProfileRoute> { ProfileScreen() }
    }
}
```

**Guidelines:**
- Always show labels (don't use icon-only in bottom nav)
- 3–5 destinations only — never fewer than 3, never more than 5
- Use `launchSingleTop = true` to avoid duplicate entries
- Use `saveState / restoreState` to preserve tab state

---

## Navigation Rail (Medium / Side)

**Use when**: 3–7 primary destinations on tablet-portrait or foldable screens (600–839dp).

```kotlin
Row(modifier = Modifier.fillMaxSize()) {
    NavigationRail(
        containerColor = MaterialTheme.colorScheme.surface,
        header = {
            // Optional FAB at top of rail
            FloatingActionButton(onClick = onCreate) {
                Icon(Icons.Default.Add, contentDescription = "Create")
            }
        }
    ) {
        // Center items vertically
        Spacer(Modifier.weight(1f))

        val navBackStackEntry by navController.currentBackStackEntryAsState()
        val currentDest = navBackStackEntry?.destination

        destinations.forEach { dest ->
            val selected = currentDest?.hierarchy?.any {
                it.hasRoute(dest.route::class)
            } == true

            NavigationRailItem(
                selected = selected,
                onClick  = {
                    navController.navigate(dest.route) {
                        popUpTo(navController.graph.findStartDestination().id) {
                            saveState = true
                        }
                        launchSingleTop = true
                        restoreState    = true
                    }
                },
                icon  = { Icon(dest.icon, contentDescription = dest.label) },
                label = { Text(dest.label) }
            )
        }

        Spacer(Modifier.weight(1f))
    }

    // Main content area
    Box(modifier = Modifier.weight(1f)) {
        NavHost(navController, startDestination = HomeRoute) {
            composable<HomeRoute>    { HomeScreen() }
            composable<SearchRoute>  { SearchScreen() }
            composable<ProfileRoute> { ProfileScreen() }
        }
    }
}
```

---

## Navigation Drawer (Expanded / Permanent)

**Use when**: Expanded screens (840dp+) — drawer is always visible, no overlay.

```kotlin
PermanentNavigationDrawer(
    drawerContent = {
        PermanentDrawerSheet(modifier = Modifier.width(240.dp)) {
            Spacer(Modifier.height(Dimens.md))

            Text(
                "App Name",
                modifier = Modifier.padding(horizontal = Dimens.md),
                style    = MaterialTheme.typography.titleMedium
            )

            Spacer(Modifier.height(Dimens.md))

            val currentDest = navController.currentBackStackEntryAsState().value?.destination
            destinations.forEach { dest ->
                val selected = currentDest?.hierarchy?.any {
                    it.hasRoute(dest.route::class)
                } == true

                NavigationDrawerItem(
                    label    = { Text(dest.label) },
                    icon     = { Icon(dest.icon, null) },
                    selected = selected,
                    onClick  = {
                        navController.navigate(dest.route) {
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            launchSingleTop = true
                            restoreState    = true
                        }
                    },
                    modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
                )
            }
        }
    }
) {
    // Main content
    NavHost(navController, startDestination = HomeRoute) {
        composable<HomeRoute>    { HomeScreen() }
        composable<SearchRoute>  { SearchScreen() }
        composable<ProfileRoute> { ProfileScreen() }
    }
}
```

## Modal Navigation Drawer (Compact with 6+ destinations)

```kotlin
val drawerState = rememberDrawerState(DrawerValue.Closed)
val scope       = rememberCoroutineScope()

ModalNavigationDrawer(
    drawerState   = drawerState,
    drawerContent = {
        ModalDrawerSheet {
            // Same content as permanent drawer
            destinations.forEach { dest ->
                NavigationDrawerItem(
                    label    = { Text(dest.label) },
                    icon     = { Icon(dest.icon, null) },
                    selected = false,
                    onClick  = {
                        scope.launch { drawerState.close() }
                        navController.navigate(dest.route)
                    },
                    modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
                )
            }
        }
    }
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("App") },
                navigationIcon = {
                    IconButton(onClick = { scope.launch { drawerState.open() } }) {
                        Icon(Icons.Default.Menu, "Open menu")
                    }
                }
            )
        }
    ) { padding ->
        NavHost(navController, HomeRoute, modifier = Modifier.padding(padding)) {
            composable<HomeRoute> { HomeScreen() }
        }
    }
}
```

---

## Tabs

**Use when**: Switching between 2+ related views within the same level (not top-level navigation).

```kotlin
// Fixed tabs (equal width)
val tabs  = listOf("Overview", "Reviews", "Related")
var selected by remember { mutableIntStateOf(0) }

Column {
    TabRow(selectedTabIndex = selected) {
        tabs.forEachIndexed { index, title ->
            Tab(
                selected = selected == index,
                onClick  = { selected = index },
                text     = { Text(title) }
            )
        }
    }

    // Content for selected tab
    when (selected) {
        0 -> OverviewTab()
        1 -> ReviewsTab()
        2 -> RelatedTab()
    }
}

// Scrollable tabs (when tabs overflow)
ScrollableTabRow(selectedTabIndex = selected) {
    tabs.forEachIndexed { index, title ->
        Tab(
            selected = selected == index,
            onClick  = { selected = index },
            text     = { Text(title) }
        )
    }
}

// Tabs with icons
TabRow(selectedTabIndex = selected) {
    Tab(selected = selected == 0, onClick = { selected = 0 },
        icon = { Icon(Icons.Default.GridView, null) }, text = { Text("Grid") })
    Tab(selected = selected == 1, onClick = { selected = 1 },
        icon = { Icon(Icons.Default.ViewList, null) }, text = { Text("List") })
}
```

---

## Top App Bar with Back Navigation

```kotlin
// Standard back navigation
TopAppBar(
    title          = { Text("Detail") },
    navigationIcon = {
        IconButton(onClick = onBack) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
        }
    }
)

// From composable using NavController
val navController = rememberNavController()
TopAppBar(
    title          = { Text("Detail") },
    navigationIcon = {
        IconButton(onClick = { navController.popBackStack() }) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
        }
    }
)
```

---

## Bottom App Bar

**Use when**: Compact screen with 3+ contextual actions (not top-level navigation).

```kotlin
Scaffold(
    bottomBar = {
        BottomAppBar(
            actions = {
                IconButton(onClick = onSearch) { Icon(Icons.Default.Search, "Search") }
                IconButton(onClick = onSort)   { Icon(Icons.Default.Sort, "Sort") }
                IconButton(onClick = onFilter) { Icon(Icons.Default.FilterList, "Filter") }
            },
            floatingActionButton = {
                FloatingActionButton(onClick = onCreate) {
                    Icon(Icons.Default.Add, "Create")
                }
            }
        )
    }
) { padding -> /* content */ }
```

---

## Adaptive Navigation (All Window Sizes)

See [references/layout-and-responsive.md](layout-and-responsive.md) §Adaptive Navigation Example for
the full implementation that switches between `NavigationBar` / `NavigationRail` / `PermanentNavigationDrawer`
based on `WindowSizeClass`.

---

## Full NavGraph Setup with Type-Safe Routes

```kotlin
// commonMain/navigation/AppNavigation.kt
@Composable
fun AppNavigation(navController: NavHostController = rememberNavController()) {
    NavHost(navController = navController, startDestination = HomeRoute) {
        composable<HomeRoute> {
            HomeScreen(
                onNavigateToDetail = { id -> navController.navigate(DetailRoute(id)) }
            )
        }
        composable<DetailRoute> { backStackEntry ->
            val route: DetailRoute = backStackEntry.toRoute()
            DetailScreen(id = route.id, onBack = { navController.popBackStack() })
        }
        composable<SearchRoute> { SearchScreen() }
        composable<ProfileRoute> { ProfileScreen() }

        // Nested graph for auth
        navigation<AuthGraph>(startDestination = LoginRoute) {
            composable<LoginRoute> {
                LoginScreen(onLoginSuccess = {
                    navController.navigate(HomeRoute) {
                        popUpTo<AuthGraph> { inclusive = true }
                    }
                })
            }
        }
    }
}
```

---

## Rules

- **Never** pass `NavController` into a ViewModel — navigate via `UiEffect`
- **Never** use string routes — use `@Serializable` type-safe routes only
- `NavigationBar` is for **compact only** — `NavigationRail` on medium, drawer on expanded
- `launchSingleTop = true` on all bottom/rail/drawer nav clicks to avoid stack duplicates
- `saveState = true` + `restoreState = true` to preserve scroll position between tabs
- Tab navigation is **within** a screen, not between top-level destinations
- `BackHandler` needed when using `NavigableListDetailPaneScaffold` — always include it

---

## Official Docs

- [Navigation Compose](https://developer.android.com/jetpack/compose/navigation)
- [Type-Safe Navigation](https://developer.android.com/guide/navigation/design/type-safety)
- [NavigationBar](https://developer.android.com/develop/ui/compose/components/navigationbar)
- [NavigationRail](https://developer.android.com/develop/ui/compose/components/navigation-rail)
- [NavigationDrawer](https://developer.android.com/develop/ui/compose/components/drawer)
- [Material3 Adaptive](https://developer.android.com/jetpack/androidx/releases/compose-material3-adaptive)
