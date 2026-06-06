# DI Options Reference

## Comparison

| | Koin | Manual DI |
|---|---|---|
| KMP support | ✅ Native | ✅ Always |
| Code gen | ❌ None | ❌ None |
| Runtime overhead | Minimal | None |
| Complexity | Low | Low–Medium |
| Best for | Most projects | Tiny apps, learning |

---

## Option 1: Koin (Recommended)

### Versions

```toml
# gradle/libs.versions.toml
[versions]
koin = "4.0.0"

[libraries]
koin-core         = { module = "io.insert-koin:koin-core",         version.ref = "koin" }
koin-android      = { module = "io.insert-koin:koin-android",      version.ref = "koin" }
koin-compose      = { module = "io.insert-koin:koin-compose",      version.ref = "koin" }
koin-compose-vm   = { module = "io.insert-koin:koin-compose-viewmodel", version.ref = "koin" }
```

### Gradle Dependencies

```kotlin
// composeApp/build.gradle.kts
sourceSets {
    commonMain.dependencies {
        implementation(libs.koin.core)
        implementation(libs.koin.compose)
        implementation(libs.koin.compose.vm)
    }
    androidMain.dependencies {
        implementation(libs.koin.android)
    }
}
```

### Shared Module (commonMain)

```kotlin
// commonMain/di/AppModule.kt
val sharedModule = module {
    // Use cases
    factory { GetItemsUseCase(get()) }

    // Repositories — interface bound to implementation via DI
    single<ItemRepository> { ItemRepositoryImpl(get()) }

    // ViewModels
    viewModelOf(::ItemListViewModel)
    viewModelOf(::ItemDetailViewModel)
}
```

### Android Module (androidMain)

```kotlin
// androidMain/di/AndroidModule.kt
val androidModule = module {
    single<DatabaseDriver> { AndroidDatabaseDriver(androidContext()) }
    single<LocalDataSource> { AndroidLocalDataSource(get()) }
}
```

### Desktop Module (jvmMain)

```kotlin
// jvmMain/di/DesktopModule.kt
val desktopModule = module {
    single<DatabaseDriver> { DesktopDatabaseDriver() }
    single<LocalDataSource> { DesktopLocalDataSource(get()) }
}
```

### Android Initialization

```kotlin
// androidMain — Application class
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        startKoin {
            androidLogger(Level.DEBUG)
            androidContext(this@MyApplication)
            modules(sharedModule, androidModule)
        }
    }
}
```

```xml
<!-- AndroidManifest.xml -->
<application
    android:name=".MyApplication"
    ...>
```

### Desktop Initialization

```kotlin
// jvmMain — main.kt
fun main() = application {
    startKoin {
        modules(sharedModule, desktopModule)
    }
    Window(onCloseRequest = ::exitApplication, title = "App Name") {
        App()
    }
}
```

### Injecting in Composables

```kotlin
// Inject ViewModel in Compose (commonMain or platform-specific)
@Composable
fun ItemListScreen() {
    val viewModel: ItemListViewModel = koinViewModel()
    // ...
}

// Inject a plain dependency in Compose
@Composable
fun SomeScreen() {
    val service: SomeService = koinInject()
}
```

### Module Organization Pattern

```
di/
├── AppModule.kt         ← commonMain: shared use cases, repos, VMs
├── AndroidModule.kt     ← androidMain: platform-specific bindings
└── DesktopModule.kt     ← jvmMain: desktop-specific bindings
```

---

## Option 2: Manual DI (Constructor Injection)

No library required. Use a single `AppContainer` object per platform.

### Shared Interface (commonMain)

```kotlin
// commonMain/di/AppContainer.kt
interface AppContainer {
    val itemRepository: ItemRepository
    val getItemsUseCase: GetItemsUseCase
}
```

### Android Implementation (androidMain)

```kotlin
// androidMain/di/AndroidAppContainer.kt
class AndroidAppContainer(context: Context) : AppContainer {
    private val localDataSource: LocalDataSource = AndroidLocalDataSource(context)
    override val itemRepository: ItemRepository  = ItemRepositoryImpl(localDataSource)
    override val getItemsUseCase: GetItemsUseCase = GetItemsUseCase(itemRepository)
}

// androidMain — Application class
class MyApplication : Application() {
    lateinit var container: AppContainer

    override fun onCreate() {
        super.onCreate()
        container = AndroidAppContainer(this)
    }
}

// In Activity / Fragment
val container = (application as MyApplication).container
val viewModel = ItemListViewModel(container.getItemsUseCase)
```

### Desktop Implementation (jvmMain)

```kotlin
// jvmMain/di/DesktopAppContainer.kt
class DesktopAppContainer : AppContainer {
    private val localDataSource: LocalDataSource = DesktopLocalDataSource()
    override val itemRepository: ItemRepository  = ItemRepositoryImpl(localDataSource)
    override val getItemsUseCase: GetItemsUseCase = GetItemsUseCase(itemRepository)
}

// jvmMain — main.kt
val container: AppContainer = DesktopAppContainer()

fun main() = application {
    Window(onCloseRequest = ::exitApplication) {
        App(container = container)
    }
}
```

---

## Rules for Both Approaches

- All interfaces are defined in `commonMain`
- All platform-specific implementations live in `androidMain` / `jvmMain`
- ViewModels always receive dependencies via constructor — never use `by lazy` or singletons inside VMs
- Never reference `Context` in `commonMain` — inject it only in `androidMain`
