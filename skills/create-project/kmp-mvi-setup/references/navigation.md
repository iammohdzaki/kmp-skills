# Navigation Reference

## Library: navigation-compose (Jetpack)

Using the **type-safe navigation API** introduced in Navigation Compose 2.8+.
Routes are `@Serializable` data classes / objects — no string routes.

---

## Version Catalog

```toml
# gradle/libs.versions.toml
[versions]
navigation = "2.8.0"

[libraries]
navigation-compose = { module = "androidx.navigation:navigation-compose", version.ref = "navigation" }
```

```kotlin
// composeApp/build.gradle.kts
commonMain.dependencies {
    implementation(libs.navigation.compose)
}
```

---

## Defining Routes

All routes live in a single `Routes.kt` file in `commonMain`:

```kotlin
// commonMain/navigation/Routes.kt
import kotlinx.serialization.Serializable

// Screen with no arguments
@Serializable
object HomeRoute

@Serializable
object SettingsRoute

// Screen with required arguments
@Serializable
data class DetailRoute(val id: String)

@Serializable
data class ProfileRoute(val userId: String, val showEdit: Boolean = false)

// Nested graph root
@Serializable
object AuthGraph

@Serializable
object LoginRoute
```

---

## NavHost Setup

```kotlin
// commonMain/navigation/AppNavigation.kt
@Composable
fun AppNavigation(
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController  = navController,
        startDestination = HomeRoute
    ) {
        // Simple screen — no args
        composable<HomeRoute> {
            HomeScreen(
                onNavigateToDetail  = { id -> navController.navigate(DetailRoute(id)) },
                onNavigateToSettings = { navController.navigate(SettingsRoute) }
            )
        }

        // Screen with args — extracted via toRoute()
        composable<DetailRoute> { backStackEntry ->
            val route: DetailRoute = backStackEntry.toRoute()
            DetailScreen(
                id       = route.id,
                onBack   = { navController.popBackStack() }
            )
        }

        composable<SettingsRoute> {
            SettingsScreen(onBack = { navController.popBackStack() })
        }

        // Nested graph
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

## Common Navigation Patterns

### Navigate and clear back stack (login → home)

```kotlin
navController.navigate(HomeRoute) {
    popUpTo(0) { inclusive = true }  // clear entire stack
    launchSingleTop = true
}
```

### Navigate up (back button)

```kotlin
navController.popBackStack()
// or
navController.navigateUp()
```

### Navigate avoiding duplicates (bottom nav)

```kotlin
navController.navigate(HomeRoute) {
    popUpTo(navController.graph.findStartDestination().id) {
        saveState = true
    }
    launchSingleTop = true
    restoreState    = true
}
```

---

## Bottom Navigation Bar Integration

```kotlin
// commonMain/navigation/BottomNavItem.kt
sealed class BottomNavItem(val route: Any, val label: String, val icon: ImageVector) {
    object Home     : BottomNavItem(HomeRoute,     "Home",    Icons.Default.Home)
    object Settings : BottomNavItem(SettingsRoute, "Settings", Icons.Default.Settings)
}

val bottomNavItems = listOf(BottomNavItem.Home, BottomNavItem.Settings)
```

```kotlin
// In your scaffold
val navBackStackEntry by navController.currentBackStackEntryAsState()
val currentDestination = navBackStackEntry?.destination

Scaffold(
    bottomBar = {
        NavigationBar {
            bottomNavItems.forEach { item ->
                NavigationBarItem(
                    selected = currentDestination?.hierarchy?.any {
                        it.hasRoute(item.route::class)
                    } == true,
                    onClick = { navController.navigate(item.route) { ... } },
                    icon    = { Icon(item.icon, contentDescription = item.label) },
                    label   = { Text(item.label) }
                )
            }
        }
    }
) { paddingValues ->
    AppNavigation(
        navController = navController,
        modifier      = Modifier.padding(paddingValues)
    )
}
```

---

## Passing NavController to ViewModels

**Never** pass `NavController` to a ViewModel. Use `UiEffect` instead:

```kotlin
// ViewModel sends effect
sendEffect { DetailUiEffect.NavigateTo(DetailRoute(itemId)) }

// UI collects and navigates
LaunchedEffect(Unit) {
    viewModel.effect.collect { effect ->
        when (effect) {
            is DetailUiEffect.NavigateTo -> navController.navigate(effect.route)
            is DetailUiEffect.NavigateBack -> navController.popBackStack()
        }
    }
}
```

---

## Rules

- All routes in one file (`Routes.kt`) — keeps navigation graph readable at a glance
- Use `@Serializable` objects for screens with no arguments, `data class` for screens with arguments
- **Never** navigate directly from a ViewModel — always via `UiEffect`
- **Never** use raw string routes — use the type-safe API only
- Use `launchSingleTop = true` on bottom nav items to avoid duplicate screens
- Arguments must be primitives or `@Serializable` types — no complex objects as route params (use IDs instead)

---

## Official Docs

- [Navigation Compose](https://developer.android.com/jetpack/compose/navigation)
- [Type-safe navigation](https://developer.android.com/guide/navigation/design/type-safety)
- [Nested graphs](https://developer.android.com/guide/navigation/design/nested-graphs)
