---
name: kmp-mvi-setup
category: create-project
description: >
  Interactive skill for scaffolding a complete Kotlin Multiplatform (KMP) project
  using MVI architecture. Covers State/Event/Effect pattern, Compose Multiplatform,
  DI, type-safe navigation, and image loading. Asks user for preferences before
  generating any code.
targets:
  - antigravity
  - claude
  - cursor
  - windsurf
sources:
  - https://www.kotlinlang.org/docs/multiplatform/
  - https://www.jetbrains.com/compose-multiplatform/
  - https://insert-koin.io/
  - https://developer.android.com/jetpack/compose/navigation
---

# KMP + MVI Project Setup Skill

This skill guides you through creating a **production-ready Kotlin Multiplatform (KMP) project**
using **MVI (Model-View-Intent)** architecture with Compose Multiplatform.

> **IMPORTANT**: Before writing any code or project structure, you MUST ask the user
> all Pre-flight Questions below and wait for answers. Never assume defaults silently.

> **PREREQUISITE SKILLS**: Read these skills first before generating any files:
> - [`kmp-versions`](../kmp-versions/SKILL.md) — always fetch live compatible versions from official sources
> - [`kmp-project-structure`](../kmp-project-structure/SKILL.md) — use the new multi-module layout (`shared/` + `androidApp/`)

---

## Pre-flight Questions

Ask the user these questions **in a single message** before generating anything.
Wait for all answers before reading any reference files or writing any code.

```
Before I scaffold your KMP project, I need a few details:

1. ℹ️ App name & package
   What is your app name and base package?
   e.g. App Name: "Task Manager", Package: "com.example.taskmanager"

2. 📱 Target platforms
   - Android only
   - Android + Desktop (JVM)
   - Android + Desktop + iOS  (requires macOS for iOS build)

3. 🔧 Dependency Injection
   - Koin  (recommended — KMP-native, simple DSL, no code gen)
   - Manual DI  (constructor injection, no library)
   - Other — please specify

4. 🌐 Networking
   Do you need HTTP API calls?
   - Ktor  (recommended — KMP-native, multiplatform engines)
   - None  (no networking needed)
   - Other — please specify

5. 📦 Serialization
   Do you need JSON or data encoding?
   - kotlinx.serialization  (recommended — works on all targets)
   - None  (no serialization needed)
   - Other — please specify

6. 🖼️ Image loading
   Do you need to load images from URLs?
   - Coil 3 + Landscapist  (recommended — KMP-ready, composable wrappers)
   - Coil 3 standalone  (ImageRequest API directly)
   - None  (skip for now)
   - Other — please specify

7. 🦭 Navigation
   Do you want type-safe navigation-compose scaffolded?
   - Yes  (recommended — @Serializable routes, NavHost, NavController via Effect)
   - No  (I’ll add it later)

8. 🗄️ Local Storage / Database
   Do you need persistent local data storage?
   - multiplatform-settings  (small data: prefs, flags, settings — KMP-native)
   - SQLDelight  (recommended for structured data — full KMP: Android + iOS + Desktop)
   - Room  (structured data — Android/JVM only, no iOS)
   - Both multiplatform-settings + SQLDelight  (prefs + structured data)
   - None  (no local storage needed)
```

---

## Module Loader

After the user answers the pre-flight questions, read **only** the reference files that match
their choices. Do not load references for modules the user did not select.

| User selects | Reference file to read | When to skip |
|---|---|---|
| Any (always) | `references/mvi-patterns.md` | Never — always read this |
| Koin | `references/di-options.md` | User chose Manual DI |
| Ktor | `references/network-ktor.md` | User chose None |
| kotlinx.serialization | `references/serialization.md` | User chose None |
| Coil / Landscapist | `references/image-loading.md` | User chose None |
| Navigation | `references/navigation.md` | User chose No |
| multiplatform-settings | `references/storage-datastore.md` | User chose None |
| SQLDelight | `references/storage-sqldelight.md` | User chose None |
| Room | `references/storage-room.md` | User chose None |
| Both settings + SQLDelight | Both `storage-datastore.md` + `storage-sqldelight.md` | — |

> **Rule**: Only include libraries, Gradle entries, and code from the selected reference files.
> Never add a dependency the user did not ask for.

### 🤖 AI Self-Extension Rule

If the user requests a library **not covered by any reference file** in this skill
(e.g. WorkManager, Firebase, Apollo GraphQL, Coil-SVG, Bluetooth, etc.), the AI should:

1. **Research the library** — check its official docs and KMP compatibility.
2. **Generate the setup inline** following the same patterns used in existing reference files:
   - Version catalog entries with `FETCH_FROM_OFFICIAL_SOURCE` placeholders
   - Source set dependency declarations
   - Repository / factory pattern in `commonMain`
   - `expect`/`actual` for platform-specific code if needed
   - Koin DI wiring (if Koin is selected)
   - MVI ViewModel integration snippet
3. **Save a new reference file** at `references/<module-name>.md` so it can be reused in future projects.
4. **Add the new module to this Module Loader table** in the SKILL.md.

This keeps the skill growing organically without requiring manual updates for every possible library.

---

## After Collecting Answers

Use the answers to generate:

1. **Full project directory structure** (see `kmp-project-structure` skill)
2. `settings.gradle.kts`
3. Root `build.gradle.kts`
4. `shared/build.gradle.kts` — only selected dependencies
5. `androidApp/build.gradle.kts`
6. `desktopApp/build.gradle.kts` (if Desktop selected)
7. `gradle/libs.versions.toml` — only selected libraries, fetched versions (see below)
8. MVI base files: `UiState.kt`, `UiEvent.kt`, `UiEffect.kt`, `BaseViewModel.kt`
9. DI module files — based on chosen DI framework
10. `AppNavigation.kt` — if navigation selected
11. Network/serialization setup — if selected
12. Entry points: `MainActivity.kt`, `main.kt` (Desktop), `App.kt` (shared)

---

## Project Structure to Generate

> Use the **new multi-module layout** (required for AGP 9.0+). See [kmp-project-structure](../kmp-project-structure/SKILL.md) for full file contents.

```
<AppName>/
├── shared/                                ← KMP library: ALL shared code + shared UI
│   ├── build.gradle.kts                   ← com.android.kotlin.multiplatform.library + kotlin.multiplatform
│   └── src/
│       ├── commonMain/kotlin/<package>/
│       │   ├── App.kt                     ← Root @Composable (shared)
│       │   ├── mvi/
│       │   │   ├── UiState.kt
│       │   │   ├── UiEvent.kt
│       │   │   ├── UiEffect.kt
│       │   │   └── BaseViewModel.kt
│       │   ├── di/
│       │   │   └── AppModule.kt           ← Shared DI module
│       │   └── navigation/
│       │       └── AppNavigation.kt       ← NavHost + routes (if selected)
│       ├── androidMain/kotlin/<package>/
│       │   └── di/
│       │       └── AndroidModule.kt
│       └── jvmMain/kotlin/<package>/      ← only if Desktop selected
│           └── di/
│               └── DesktopModule.kt
│
├── androidApp/                            ← Thin Android shell (entry point only)
│   ├── build.gradle.kts                   ← com.android.application only
│   └── src/main/kotlin/<package>/
│       ├── MainActivity.kt                ← setContent { App() }
│       └── MyApplication.kt              ← DI init (if Koin)
│
├── desktopApp/                            ← only if Desktop selected
│   ├── build.gradle.kts                   ← kotlin("jvm")
│   └── src/main/kotlin/
│       └── main.kt                        ← application { Window { App() } }
│
├── iosApp/                                ← Xcode project (if iOS selected)
├── gradle/
│   └── libs.versions.toml
├── build.gradle.kts
├── settings.gradle.kts
├── gradle.properties
└── .gitignore
```

---

## MVI Architecture

See [references/mvi-patterns.md](references/mvi-patterns.md) for the complete pattern.

### The Three Contracts

Every feature in the app follows this contract:

```kotlin
// State — immutable snapshot of what the UI renders
data class FeatureUiState(
    val isLoading: Boolean = false,
    val data: List<ItemModel> = emptyList(),
    val error: String? = null
)

// Event — all user actions / one-directional: UI → ViewModel
sealed interface FeatureUiEvent {
    data class LoadData(val id: String) : FeatureUiEvent
    data object RetryClicked : FeatureUiEvent
    data object DismissError : FeatureUiEvent
}

// Effect — one-shot side effects, not stored in State
sealed interface FeatureUiEffect {
    data class NavigateTo(val route: String) : FeatureUiEffect
    data class ShowSnackbar(val message: String) : FeatureUiEffect
}
```

### BaseViewModel (commonMain)

```kotlin
// commonMain — shared ViewModel base, no Android dependency
abstract class BaseViewModel<State, Event, Effect> {
    private val initialState: State by lazy { createInitialState() }

    protected val _state: MutableStateFlow<State> = MutableStateFlow(initialState)
    val state: StateFlow<State> = _state.asStateFlow()

    private val _effect = MutableSharedFlow<Effect>(extraBufferCapacity = 16)
    val effect: SharedFlow<Effect> = _effect.asSharedFlow()

    protected val viewModelScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    abstract fun createInitialState(): State
    abstract fun onEvent(event: Event)

    protected fun setState(reduce: State.() -> State) {
        _state.update { it.reduce() }
    }

    protected fun sendEffect(effect: Effect) {
        viewModelScope.launch { _effect.emit(effect) }
    }

    open fun onCleared() {
        viewModelScope.cancel()
    }
}
```

---

## DI Setup

See [references/di-options.md](references/di-options.md) for full setup per framework.

### If Koin selected

```kotlin
// commonMain — sharedModule
val sharedModule = module {
    // Add your shared dependencies here
}

// androidMain — Android Application.onCreate()
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        startKoin {
            androidContext(this@MyApplication)
            modules(sharedModule, androidModule)
        }
    }
}

// jvmMain — main()
fun main() = application {
    startKoin { modules(sharedModule, desktopModule) }
    Window(onCloseRequest = ::exitApplication, title = "AppName") {
        App()
    }
}
```

---

## Navigation Setup

See [references/navigation.md](references/navigation.md) for full setup.

### If navigation-compose selected

```kotlin
// commonMain — type-safe routes using @Serializable
@Serializable object HomeRoute
@Serializable data class DetailRoute(val id: String)

// NavHost setup
@Composable
fun AppNavigation(navController: NavHostController = rememberNavController()) {
    NavHost(navController = navController, startDestination = HomeRoute) {
        composable<HomeRoute> {
            HomeScreen(onNavigateToDetail = { id ->
                navController.navigate(DetailRoute(id))
            })
        }
        composable<DetailRoute> { backStackEntry ->
            val route: DetailRoute = backStackEntry.toRoute()
            DetailScreen(id = route.id)
        }
    }
}
```

---

## Image Loading Setup

See [references/image-loading.md](references/image-loading.md) for full setup.

---

## Version Catalog

> ⚠️ **Never hardcode versions.** Always follow the **5-step protocol** in
> [`kmp-versions`](../kmp-versions/SKILL.md) to fetch live compatible versions before filling
> in `libs.versions.toml`. The table below shows which sources to check per library:

| Library | Fetch version from |
|---|---|
| Kotlin / KGP | https://kotlinlang.org/docs/multiplatform/multiplatform-compatibility-guide.html |
| AGP | https://developer.android.com/build/releases/gradle-plugin |
| Compose Multiplatform | https://plugins.gradle.org/plugin/org.jetbrains.compose |
| kotlinx-coroutines | https://github.com/Kotlin/kotlinx.coroutines/releases |
| kotlinx-serialization | https://github.com/Kotlin/kotlinx.serialization/releases |
| Ktor | https://github.com/ktorio/ktor/releases |
| Koin | https://github.com/InsertKoinIO/koin/releases |
| Lifecycle / ViewModel | https://developer.android.com/jetpack/androidx/releases/lifecycle |
| Navigation Compose | https://developer.android.com/jetpack/androidx/releases/navigation |
| Coil 3 | https://github.com/coil-kt/coil/releases |
| Landscapist | https://github.com/skydoves/landscapist/releases |

### Always-included catalog entries

```toml
[versions]
# ── Fetch from official sources (see kmp-versions skill) ──────────────────────
kotlin               = "FETCH"
agp                  = "FETCH"
composeMultiplatform = "FETCH"
coroutines           = "FETCH"
lifecycle            = "FETCH"

[libraries]
# Compose Multiplatform — explicit (compose.* accessors deprecated in CMP 1.10)
compose-runtime              = { module = "org.jetbrains.compose.runtime:runtime",                version.ref = "composeMultiplatform" }
compose-foundation           = { module = "org.jetbrains.compose.foundation:foundation",           version.ref = "composeMultiplatform" }
compose-ui                   = { module = "org.jetbrains.compose.ui:ui",                           version.ref = "composeMultiplatform" }
compose-material3            = { module = "org.jetbrains.compose.material3:material3",             version.ref = "composeMultiplatform" }
# material-icons-core is NOT transitive since CMP 1.8.2 — always declare explicitly
compose-material-icons-core  = { module = "org.jetbrains.compose.material:material-icons-core",   version.ref = "composeMultiplatform" }
compose-ui-tooling-preview   = { module = "org.jetbrains.compose.ui:ui-tooling-preview",          version.ref = "composeMultiplatform" }

# Kotlin
kotlinx-coroutines-core      = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core",        version.ref = "coroutines" }
lifecycle-viewmodel          = { module = "androidx.lifecycle:lifecycle-viewmodel",               version.ref = "lifecycle" }
kotlin-test                  = { module = "org.jetbrains.kotlin:kotlin-test",                     version.ref = "kotlin" }

# Android entry point
androidx-activity-compose    = { module = "androidx.activity:activity-compose",                  version = "FETCH" }

[plugins]
kotlinMultiplatform   = { id = "org.jetbrains.kotlin.multiplatform",            version.ref = "kotlin" }
androidApplication    = { id = "com.android.application",                       version.ref = "agp" }
# AGP 9+ new plugin for the shared module
androidKmpLibrary     = { id = "com.android.kotlin.multiplatform.library",      version.ref = "agp" }
composeMultiplatform  = { id = "org.jetbrains.compose",                         version.ref = "composeMultiplatform" }
composeCompiler       = { id = "org.jetbrains.kotlin.plugin.compose",           version.ref = "kotlin" }
```

### Add-on catalog entries (include only if selected)

> Each module's reference file contains its exact `[versions]` and `[libraries]` entries.
> Copy them into `libs.versions.toml` if the user selected that module.

| Module | Reference file with entries |
|---|---|
| kotlinx.serialization | `references/serialization.md` — `[versions]` + `[libraries]` + `[plugins]` |
| Ktor | `references/network-ktor.md` — `[versions]` + `[libraries]` |
| Koin | `references/di-options.md` — `[versions]` + `[libraries]` |
| Navigation Compose | `references/navigation.md` — `[versions]` + `[libraries]` |
| Coil + Landscapist | `references/image-loading.md` — `[versions]` + `[libraries]` |

---

## Rules & Constraints

- **Never** write any code until all pre-flight questions are answered.
- **Never** include a library the user did not select.
- All business logic lives in `commonMain` — never in `androidMain` or `jvmMain`.
- `androidMain` and `jvmMain` contain only: entry points, platform-specific DI modules, and platform `actual` implementations.
- Use `interface` + DI for platform differences — avoid `expect class` (Beta warning).
- All shared ViewModels extend `BaseViewModel` defined in `commonMain`.
- Use `data class` for `UiState`, `sealed interface` for `UiEvent` and `UiEffect`.
- Navigation routes must use `@Serializable` data classes/objects (Kotlin 2.x type-safe API).
- Never hardcode strings — use a `Strings` object or resource file.

---

## Official Docs

- [KMP Overview](https://www.kotlinlang.org/docs/multiplatform/)
- [Compose Multiplatform](https://www.jetbrains.com/compose-multiplatform/)
- [Koin for KMP](https://insert-koin.io/docs/reference/koin-mp/kmp/)
- [Navigation Compose](https://developer.android.com/jetpack/compose/navigation)
- [Coil 3](https://coil-kt.github.io/coil/)
- [Landscapist](https://github.com/skydoves/landscapist)
