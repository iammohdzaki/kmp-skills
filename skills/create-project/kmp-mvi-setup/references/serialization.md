# Serialization — kotlinx.serialization (KMP)

> Read this file only when the user selected **kotlinx.serialization** for JSON/data encoding.

`kotlinx.serialization` is the official Kotlin serialization library. It works across all KMP
targets (Android, Desktop, iOS, Web) from `commonMain` with zero platform-specific code needed.

---

## Version Catalog Entries

> ⚠️ Fetch the latest stable version from: https://github.com/Kotlin/kotlinx.serialization/releases

```toml
[versions]
serialization = "FETCH_FROM_OFFICIAL_SOURCE"   # https://github.com/Kotlin/kotlinx.serialization/releases

[libraries]
# JSON serialization — the most common format
kotlinx-serialization-json = { module = "org.jetbrains.kotlinx:kotlinx-serialization-json", version.ref = "serialization" }

# Optional formats (add only if needed)
# kotlinx-serialization-cbor     = { module = "org.jetbrains.kotlinx:kotlinx-serialization-cbor",     version.ref = "serialization" }
# kotlinx-serialization-protobuf = { module = "org.jetbrains.kotlinx:kotlinx-serialization-protobuf", version.ref = "serialization" }

[plugins]
kotlinSerialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
# Note: version.ref = "kotlin" — the serialization plugin version ALWAYS matches Kotlin version
```

---

## Plugin Application

### Root `build.gradle.kts`

```kotlin
plugins {
    alias(libs.plugins.kotlinSerialization) apply false
}
```

### `shared/build.gradle.kts`

```kotlin
plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.kotlinSerialization)   // ← add this
    // … other plugins
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation(libs.kotlinx.serialization.json)
        }
    }
}
```

---

## Core Usage

### Annotating models

```kotlin
// commonMain/kotlin/<pkg>/model/Item.kt
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerialName

@Serializable
data class Item(
    val id: String,
    val title: String,
    @SerialName("created_at")        // map snake_case JSON key
    val createdAt: String,
    val tags: List<String> = emptyList(),
    val metadata: Map<String, String> = emptyMap()
)

@Serializable
data class ApiResponse<T>(
    val data: T,
    val success: Boolean,
    val message: String? = null
)
```

### Encoding / decoding manually

```kotlin
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString

// Configure once — share the instance via DI
val json = Json {
    ignoreUnknownKeys = true    // tolerate extra keys from server
    isLenient = true            // allow unquoted keys / trailing commas
    prettyPrint = false         // compact for network
    encodeDefaults = false      // don't send null/default fields
    coerceInputValues = true    // use defaults when server sends null for non-null field
}

// Decode
val item: Item = json.decodeFromString("""{"id":"1","title":"Hello"}""")

// Encode
val jsonString: String = json.encodeToString(item)
```

---

## Sealed Classes & Polymorphism

```kotlin
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonClassDiscriminator
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic

@Serializable
sealed interface ApiEvent

@Serializable
data class MessageEvent(val text: String) : ApiEvent

@Serializable
data class ErrorEvent(val code: Int, val reason: String) : ApiEvent

// Decode polymorphic type
val event: ApiEvent = json.decodeFromString(
    """{"type":"MessageEvent","text":"Hello"}"""
)
```

---

## Integration with Ktor

When Ktor is also selected, serialization is plugged in via `ContentNegotiation`:

```kotlin
// In HttpClientFactory (platform actual files)
install(ContentNegotiation) {
    json(Json {
        ignoreUnknownKeys = true
        isLenient = true
    })
}
```

The `Json` instance is shared — if you configure it in a DI module, pass it to both Ktor and
any manual decode sites.

---

## DI Wiring (Koin)

```kotlin
// commonMain/kotlin/<pkg>/di/SerializationModule.kt
package <pkg>.di

import kotlinx.serialization.json.Json
import org.koin.dsl.module

val serializationModule = module {
    single {
        Json {
            ignoreUnknownKeys = true
            isLenient = true
            encodeDefaults = false
            coerceInputValues = true
        }
    }
}
```

Inject `Json` wherever you need it — repositories, local storage, etc.

---

## Local Storage with Serialization

Use serialization to persist complex objects via `DataStore` or simple `Settings` libraries:

```kotlin
// commonMain/kotlin/<pkg>/storage/LocalStorage.kt
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString

class LocalStorage(
    private val json: Json,
    private val settings: Settings          // multiplatform-settings or DataStore
) {
    inline fun <reified T> save(key: String, value: T) {
        settings.putString(key, json.encodeToString(value))
    }

    inline fun <reified T> load(key: String): T? =
        settings.getStringOrNull(key)?.let { json.decodeFromString(it) }
}
```

---

## Common Pitfalls

| Pitfall | Fix |
|---|---|
| `@Serializable` on a class with non-serializable property | Add `@Transient` to skip, or make property type serializable |
| Sealed class `type` key missing | Add `@JsonClassDiscriminator("type")` or configure in `Json {}` |
| Polymorphic types break at runtime | Register subclasses in a `SerializersModule` and pass to `Json {}` |
| Enum serialization uses `.name` by default | Use `@SerialName("value")` on each enum entry for stable names |
| `decodeFromString` throws on missing field | Add `= defaultValue` to property in data class |

---

## Official Docs

- [kotlinx.serialization Guide](https://kotlinlang.org/docs/serialization.html)
- [Serialization Releases](https://github.com/Kotlin/kotlinx.serialization/releases)
- [JSON Builder Options](https://kotlinlang.org/api/kotlinx.serialization/kotlinx-serialization-json/kotlinx.serialization.json/-json-builder/)
