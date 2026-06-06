# Network — Ktor (KMP)

> Read this file only when the user selected **Ktor** for networking.

Ktor is the recommended KMP-native HTTP client. It runs on Android (OkHttp engine),
Desktop/JVM (CIO or Apache engine), and iOS (Darwin engine) — all from shared `commonMain` code.

---

## Version Catalog Entries

> ⚠️ Fetch the latest stable Ktor version from: https://github.com/ktorio/ktor/releases

```toml
[versions]
ktor = "FETCH_FROM_OFFICIAL_SOURCE"   # https://github.com/ktorio/ktor/releases

[libraries]
# Core client (commonMain)
ktor-client-core          = { module = "io.ktor:ktor-client-core",             version.ref = "ktor" }
ktor-client-content-neg   = { module = "io.ktor:ktor-client-content-negotiation", version.ref = "ktor" }
ktor-serialization-json   = { module = "io.ktor:ktor-serialization-kotlinx-json", version.ref = "ktor" }
ktor-client-logging       = { module = "io.ktor:ktor-client-logging",          version.ref = "ktor" }

# Platform engines — in platform-specific source sets
ktor-client-okhttp        = { module = "io.ktor:ktor-client-okhttp",           version.ref = "ktor" }  # androidMain
ktor-client-cio           = { module = "io.ktor:ktor-client-cio",              version.ref = "ktor" }  # jvmMain (Desktop)
ktor-client-darwin        = { module = "io.ktor:ktor-client-darwin",           version.ref = "ktor" }  # iosMain
```

---

## Source Set Dependencies (`shared/build.gradle.kts`)

```kotlin
kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation(libs.ktor.client.core)
            implementation(libs.ktor.client.content.neg)
            implementation(libs.ktor.serialization.json)
            implementation(libs.ktor.client.logging)
        }
        androidMain.dependencies {
            implementation(libs.ktor.client.okhttp)       // OkHttp engine for Android
        }
        val jvmMain by getting {
            dependencies {
                implementation(libs.ktor.client.cio)      // CIO engine for Desktop
            }
        }
        // iOS source set is auto-created when iosArm64/iosSimulatorArm64 targets are declared
        iosMain.dependencies {
            implementation(libs.ktor.client.darwin)       // Darwin engine for iOS
        }
    }
}
```

---

## Platform-Specific HttpClient (expect/actual)

Since engines are platform-specific, use `expect`/`actual` to provide the client:

### `commonMain` — expect declaration

```kotlin
// commonMain/kotlin/<pkg>/network/HttpClientFactory.kt
package <pkg>.network

import io.ktor.client.HttpClient

expect fun createHttpClient(): HttpClient
```

### `androidMain` — actual

```kotlin
// androidMain/kotlin/<pkg>/network/HttpClientFactory.android.kt
package <pkg>.network

import io.ktor.client.HttpClient
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.logging.LogLevel
import io.ktor.client.plugins.logging.Logging
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json

actual fun createHttpClient(): HttpClient = HttpClient(OkHttp) {
    install(ContentNegotiation) {
        json(Json { ignoreUnknownKeys = true; isLenient = true })
    }
    install(Logging) { level = LogLevel.HEADERS }
}
```

### `jvmMain` — actual (Desktop)

```kotlin
// jvmMain/kotlin/<pkg>/network/HttpClientFactory.jvm.kt
package <pkg>.network

import io.ktor.client.HttpClient
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.logging.LogLevel
import io.ktor.client.plugins.logging.Logging
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json

actual fun createHttpClient(): HttpClient = HttpClient(CIO) {
    install(ContentNegotiation) {
        json(Json { ignoreUnknownKeys = true; isLenient = true })
    }
    install(Logging) { level = LogLevel.HEADERS }
}
```

### `iosMain` — actual

```kotlin
// iosMain/kotlin/<pkg>/network/HttpClientFactory.ios.kt
package <pkg>.network

import io.ktor.client.HttpClient
import io.ktor.client.engine.darwin.Darwin
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.logging.LogLevel
import io.ktor.client.plugins.logging.Logging
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json

actual fun createHttpClient(): HttpClient = HttpClient(Darwin) {
    install(ContentNegotiation) {
        json(Json { ignoreUnknownKeys = true; isLenient = true })
    }
    install(Logging) { level = LogLevel.HEADERS }
}
```

---

## Repository Pattern (commonMain)

Wire the `HttpClient` through your DI and repository layer — not directly into ViewModels:

```kotlin
// commonMain/kotlin/<pkg>/network/ApiService.kt
package <pkg>.network

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.request.get
import io.ktor.client.request.parameter

class ApiService(private val client: HttpClient) {
    suspend fun <T> safeCall(block: suspend HttpClient.() -> T): Result<T> = runCatching {
        client.block()
    }
}

// commonMain/kotlin/<pkg>/repository/ItemRepository.kt
package <pkg>.repository

import <pkg>.network.ApiService
import <pkg>.model.Item

class ItemRepository(private val api: ApiService) {

    suspend fun getItems(): Result<List<Item>> = api.safeCall {
        get("https://api.example.com/items").body()
    }

    suspend fun getItem(id: String): Result<Item> = api.safeCall {
        get("https://api.example.com/items/$id").body()
    }
}
```

---

## DI Wiring (Koin)

If the project uses Koin, register the `HttpClient` and `ApiService` in the shared Koin module:

```kotlin
// commonMain/kotlin/<pkg>/di/NetworkModule.kt
package <pkg>.di

import <pkg>.network.ApiService
import <pkg>.network.createHttpClient
import <pkg>.repository.ItemRepository
import org.koin.dsl.module

val networkModule = module {
    single { createHttpClient() }
    single { ApiService(get()) }
    single { ItemRepository(get()) }
}
```

Register `networkModule` alongside your other modules in `startKoin {}`.

---

## Connecting to MVI ViewModel

```kotlin
// commonMain/kotlin/<pkg>/feature/items/ItemsViewModel.kt
class ItemsViewModel(
    private val repository: ItemRepository
) : BaseViewModel<ItemsUiState, ItemsUiEvent, ItemsUiEffect>() {

    override fun createInitialState() = ItemsUiState()

    override fun onEvent(event: ItemsUiEvent) {
        when (event) {
            is ItemsUiEvent.LoadItems -> loadItems()
            is ItemsUiEvent.RetryClicked -> loadItems()
        }
    }

    private fun loadItems() {
        viewModelScope.launch {
            setState { copy(isLoading = true, error = null) }
            repository.getItems()
                .onSuccess { items ->
                    setState { copy(isLoading = false, items = items) }
                }
                .onFailure { e ->
                    setState { copy(isLoading = false, error = e.message) }
                    sendEffect(ItemsUiEffect.ShowSnackbar("Failed to load"))
                }
        }
    }
}
```

---

## Error Handling

Define a sealed `NetworkError` in `commonMain` for clean error mapping:

```kotlin
sealed class NetworkError : Exception() {
    data class HttpError(val code: Int, override val message: String?) : NetworkError()
    data object NoInternet : NetworkError()
    data class UnknownError(override val cause: Throwable?) : NetworkError()
}
```

Map Ktor exceptions in `ApiService.safeCall {}` to your error types as needed.

---

## Official Docs

- [Ktor Client](https://ktor.io/docs/client-create-multiplatform-application.html)
- [Ktor KMP Tutorial](https://ktor.io/docs/client-create-multiplatform-application.html)
- [Ktor Releases](https://github.com/ktorio/ktor/releases)
