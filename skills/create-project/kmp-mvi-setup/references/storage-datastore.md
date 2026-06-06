# Storage — DataStore (Small / Preferences Data)

> Read this file when the user selected **DataStore** for local storage of small, key-value
> or typed preference data. DataStore is KMP-compatible via AndroidX DataStore and
> multiplatform-settings as a cross-platform alternative.

---

## When to use DataStore

| Scenario | Use |
|---|---|
| User preferences (theme, language, onboarding seen) | ✅ DataStore Preferences |
| Small typed objects (auth token, last sync time) | ✅ DataStore Proto |
| Feature flags, app settings | ✅ DataStore Preferences |
| Large structured data, queried/filtered | ❌ Use SQLDelight instead |
| Offline-first app data cache | ❌ Use SQLDelight instead |

---

## Option A — multiplatform-settings (Recommended for KMP)

`multiplatform-settings` by Russell Wolf is the simplest KMP-native solution for key-value
storage. It wraps `SharedPreferences` on Android and `NSUserDefaults` on iOS — all from
`commonMain`.

### Version Catalog Entries

> ⚠️ Fetch latest stable from: https://github.com/russhwolf/multiplatform-settings/releases

```toml
[versions]
multiplatformSettings = "FETCH_FROM_OFFICIAL_SOURCE"

[libraries]
# Core (commonMain)
multiplatform-settings          = { module = "com.russhwolf:multiplatform-settings",              version.ref = "multiplatformSettings" }
# With kotlinx.serialization support (store typed objects)
multiplatform-settings-serialization = { module = "com.russhwolf:multiplatform-settings-serialization", version.ref = "multiplatformSettings" }
# Coroutines/Flow support
multiplatform-settings-coroutines = { module = "com.russhwolf:multiplatform-settings-coroutines", version.ref = "multiplatformSettings" }
```

### Source Set Dependencies

```kotlin
// shared/build.gradle.kts
commonMain.dependencies {
    implementation(libs.multiplatform.settings)
    implementation(libs.multiplatform.settings.coroutines)        // Flow support
    implementation(libs.multiplatform.settings.serialization)     // if serialization selected
}
```

### Platform Setup

`Settings` instances are created via platform-specific factories. Use `expect`/`actual`:

```kotlin
// commonMain/kotlin/<pkg>/storage/SettingsFactory.kt
import com.russhwolf.settings.Settings
expect fun createSettings(): Settings
```

```kotlin
// androidMain/kotlin/<pkg>/storage/SettingsFactory.android.kt
import android.content.Context
import com.russhwolf.settings.AndroidSettings
import com.russhwolf.settings.Settings

actual fun createSettings(): Settings =
    AndroidSettings(context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE))
```

```kotlin
// jvmMain/kotlin/<pkg>/storage/SettingsFactory.jvm.kt (Desktop)
import com.russhwolf.settings.PreferencesSettings
import com.russhwolf.settings.Settings
import java.util.prefs.Preferences

actual fun createSettings(): Settings =
    PreferencesSettings(Preferences.userRoot().node("app_prefs"))
```

### Repository Pattern (commonMain)

```kotlin
// commonMain/kotlin/<pkg>/storage/PreferencesRepository.kt
package <pkg>.storage

import com.russhwolf.settings.Settings
import com.russhwolf.settings.coroutines.toFlowSettings
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class PreferencesRepository(private val settings: Settings) {

    private val flowSettings = settings.toFlowSettings()

    // Primitive values
    var isDarkMode: Boolean
        get() = settings.getBoolean(KEY_DARK_MODE, false)
        set(value) = settings.putBoolean(KEY_DARK_MODE, value)

    var onboardingCompleted: Boolean
        get() = settings.getBoolean(KEY_ONBOARDING, false)
        set(value) = settings.putBoolean(KEY_ONBOARDING, value)

    // Reactive Flow
    val isDarkModeFlow: Flow<Boolean> =
        flowSettings.getBooleanFlow(KEY_DARK_MODE, false)

    // Typed object with serialization
    inline fun <reified T : Any> saveObject(key: String, value: T) {
        settings.encodeValue(key, value)    // requires multiplatform-settings-serialization
    }

    inline fun <reified T : Any> loadObject(key: String, default: T): T =
        settings.decodeValueOrDefault(key, default)

    fun clear() = settings.clear()

    companion object {
        private const val KEY_DARK_MODE   = "dark_mode"
        private const val KEY_ONBOARDING  = "onboarding_done"
    }
}
```

---

## Option B — AndroidX DataStore (Android-only)

Use this only when targeting **Android-only** (not KMP shared). Not recommended for shared code.

### Version Catalog Entries

> ⚠️ Fetch latest from: https://developer.android.com/jetpack/androidx/releases/datastore

```toml
[versions]
datastore = "FETCH_FROM_OFFICIAL_SOURCE"

[libraries]
# Preferences DataStore (key-value, no schema)
datastore-preferences = { module = "androidx.datastore:datastore-preferences", version.ref = "datastore" }
# Proto DataStore (typed, requires Protobuf schema)
datastore-proto       = { module = "androidx.datastore:datastore",             version.ref = "datastore" }
```

### Usage (androidMain only)

```kotlin
// androidMain/kotlin/<pkg>/storage/DataStoreFactory.kt
import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore

val Context.dataStore by preferencesDataStore(name = "settings")

class AppPreferencesRepository(private val dataStore: DataStore<Preferences>) {

    val isDarkMode = dataStore.data
        .map { it[DARK_MODE_KEY] ?: false }

    suspend fun setDarkMode(enabled: Boolean) {
        dataStore.edit { it[DARK_MODE_KEY] = enabled }
    }

    private companion object {
        val DARK_MODE_KEY = booleanPreferencesKey("dark_mode")
    }
}
```

---

## Koin DI Wiring

```kotlin
// commonMain/kotlin/<pkg>/di/StorageModule.kt
import <pkg>.storage.PreferencesRepository
import <pkg>.storage.createSettings
import org.koin.dsl.module

val storageModule = module {
    single { createSettings() }
    single { PreferencesRepository(get()) }
}
```

Register `storageModule` in `startKoin {}`.

---

## Official Docs

- [multiplatform-settings](https://github.com/russhwolf/multiplatform-settings)
- [AndroidX DataStore](https://developer.android.com/topic/libraries/architecture/datastore)
