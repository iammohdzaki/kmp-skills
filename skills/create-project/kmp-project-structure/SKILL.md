---
name: kmp-project-structure
category: create-project
description: >
  Reference skill for the new recommended KMP project structure (2026+). Covers the
  shift from the old single-module composeApp layout to the new multi-module
  shared/ + androidApp/ + desktopApp/ structure required for AGP 9.0+. Includes
  full file and Gradle configuration for both old and new layouts.
targets:
  - antigravity
  - claude
  - cursor
  - windsurf
sources:
  - https://kotlinlang.org/docs/multiplatform/multiplatform-compatibility-guide.html
  - https://developer.android.com/kotlin/multiplatform/plugin
  - https://kmp.jetbrains.com/
---

# KMP Project Structure (2026+)

> **IMPORTANT — Structure Changed**
>
> The KMP project structure has changed significantly. The old single-module layout where
> `composeApp` held both shared code and the Android app entry point is **deprecated** and
> incompatible with AGP 9.0+.
>
> Always scaffold new projects using the **new multi-module layout** described in this skill.
> Use the [KMP Wizard](https://kmp.jetbrains.com/) to generate a reference project if unsure.

---

## Old vs New Structure

### Old Structure (pre-2026 / AGP < 9.0) — Do NOT use for new projects

```
MyApp/
├── composeApp/                         ← ⚠️ Mixed: shared code + Android app entry point
│   ├── build.gradle.kts                ← applies com.android.application + kotlin.multiplatform
│   └── src/
│       ├── commonMain/kotlin/…
│       ├── androidMain/kotlin/…        ← MainActivity lives here
│       └── jvmMain/kotlin/…
├── iosApp/                             ← Xcode project
├── gradle/libs.versions.toml
├── build.gradle.kts
└── settings.gradle.kts
```

**Problem**: AGP 9.0 forbids `com.android.application` (or `com.android.library`) from
coexisting with `org.jetbrains.kotlin.multiplatform` in the same module.

---

### New Structure (AGP 9.0+ / KMP 2.2+) — Use this for all new projects

```
MyApp/
├── shared/                             ← KMP library module (all shared code + shared UI)
│   ├── build.gradle.kts                ← applies com.android.kotlin.multiplatform.library + kotlin.multiplatform
│   └── src/
│       ├── commonMain/kotlin/<pkg>/
│       │   ├── App.kt                  ← Root @Composable (shared UI)
│       │   ├── mvi/
│       │   ├── di/
│       │   └── navigation/
│       ├── androidMain/kotlin/<pkg>/   ← Android-specific actual implementations only
│       └── jvmMain/kotlin/<pkg>/       ← Desktop-specific actual implementations only
│
├── androidApp/                         ← Thin Android shell (entry point only)
│   ├── build.gradle.kts                ← applies com.android.application only
│   └── src/main/kotlin/<pkg>/
│       └── MainActivity.kt             ← calls setContent { App() } — nothing more
│
├── desktopApp/                         ← (optional) Thin Desktop shell
│   ├── build.gradle.kts                ← applies org.jetbrains.kotlin.jvm
│   └── src/main/kotlin/
│       └── main.kt                     ← calls application { Window { App() } }
│
├── iosApp/                             ← Xcode project (unchanged)
│   └── …
│
├── gradle/
│   └── libs.versions.toml
├── build.gradle.kts                    ← root build file
├── settings.gradle.kts
└── gradle.properties
```

**Key principle**: `shared` contains everything. App modules (`androidApp`, `desktopApp`)
are **thin shells** — they only wire the platform entry point to `shared`.

---

## Module Responsibilities

| Module | Role | Gradle Plugins |
|---|---|---|
| `shared` | All KMP code: common, Android, Desktop, iOS actuals | `com.android.kotlin.multiplatform.library` + `org.jetbrains.kotlin.multiplatform` + `org.jetbrains.compose` |
| `androidApp` | Android entry point only (MainActivity) | `com.android.application` + `org.jetbrains.kotlin.android` |
| `desktopApp` | Desktop entry point only (main.kt) | `org.jetbrains.kotlin.jvm` |
| `iosApp` | Xcode project, Swift glue | N/A (Xcode project) |

---

## File Contents

### `settings.gradle.kts`

```kotlin
pluginManagement {
    repositories {
        google()
        gradlePluginPortal()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "MyApp"

include(":shared")
include(":androidApp")
include(":desktopApp")   // remove if Desktop not needed
```

---

### Root `build.gradle.kts`

```kotlin
plugins {
    // Declare plugins here but don't apply them at root level
    alias(libs.plugins.kotlinMultiplatform)    apply false
    alias(libs.plugins.androidApplication)     apply false
    alias(libs.plugins.androidKmpLibrary)      apply false
    alias(libs.plugins.composeMultiplatform)   apply false
    alias(libs.plugins.composeCompiler)        apply false
    alias(libs.plugins.kotlinSerialization)    apply false
}
```

---

### `shared/build.gradle.kts`

```kotlin
import org.jetbrains.kotlin.gradle.ExperimentalKotlinGradlePluginApi
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidKmpLibrary)      // com.android.kotlin.multiplatform.library
    alias(libs.plugins.composeMultiplatform)
    alias(libs.plugins.composeCompiler)
    alias(libs.plugins.kotlinSerialization)
}

kotlin {
    // Android target — uses the new android{} block (NOT androidTarget{})
    android {
        compilations.all {
            compileTaskProvider.configure {
                compilerOptions {
                    jvmTarget.set(JvmTarget.JVM_11)
                }
            }
        }
    }

    // Desktop target (optional)
    jvm("desktop")

    // iOS targets (optional — add only if targeting iOS)
    listOf(
        iosX64(),
        iosArm64(),
        iosSimulatorArm64()
    ).forEach { iosTarget ->
        iosTarget.binaries.framework {
            baseName = "shared"
            isStatic = true
        }
    }

    sourceSets {
        commonMain.dependencies {
            // Compose Multiplatform — use libs.* (compose.* accessors deprecated)
            implementation(libs.compose.runtime)
            implementation(libs.compose.foundation)
            implementation(libs.compose.ui)
            implementation(libs.compose.material3)
            implementation(libs.compose.material.icons.core)

            // Kotlin
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.lifecycle.viewmodel)

            // Add DI, navigation, image loading here based on user choice
        }

        androidMain.dependencies {
            implementation(libs.compose.ui.tooling.preview)
            implementation(libs.androidx.activity.compose)
        }

        val desktopMain by getting {
            dependencies {
                implementation(compose.desktop.currentOs)
            }
        }

        commonTest.dependencies {
            implementation(libs.kotlin.test)
        }
    }
}

// AGP 9+ — configure via android {} block from com.android.kotlin.multiplatform.library
android {
    namespace = "com.<yourpackage>.shared"
    compileSdk = libs.versions.android.compileSdk.get().toInt()

    defaultConfig {
        minSdk = libs.versions.android.minSdk.get().toInt()
    }
}
```

---

### `androidApp/build.gradle.kts`

```kotlin
plugins {
    alias(libs.plugins.androidApplication)
    alias(libs.plugins.composeCompiler)
    // Note: NO kotlinMultiplatform plugin here — this is a plain Android app
    kotlin("android")
}

android {
    namespace = "com.<yourpackage>"
    compileSdk = libs.versions.android.compileSdk.get().toInt()

    defaultConfig {
        applicationId = "com.<yourpackage>"
        minSdk        = libs.versions.android.minSdk.get().toInt()
        targetSdk     = libs.versions.android.targetSdk.get().toInt()
        versionCode   = 1
        versionName   = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}

dependencies {
    implementation(project(":shared"))
    implementation(libs.androidx.activity.compose)
}
```

---

### `androidApp/src/main/kotlin/<pkg>/MainActivity.kt`

```kotlin
package com.<yourpackage>

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            // App() lives in shared — androidApp knows nothing about screens
            App()
        }
    }
}
```

---

### `desktopApp/build.gradle.kts` (optional)

```kotlin
plugins {
    alias(libs.plugins.composeMultiplatform)
    alias(libs.plugins.composeCompiler)
    kotlin("jvm")
}

dependencies {
    implementation(project(":shared"))
    implementation(compose.desktop.currentOs)
}

compose.desktop {
    application {
        mainClass = "com.<yourpackage>.MainKt"

        nativeDistributions {
            targetFormats(
                org.jetbrains.compose.desktop.application.dsl.TargetFormat.Dmg,
                org.jetbrains.compose.desktop.application.dsl.TargetFormat.Msi,
                org.jetbrains.compose.desktop.application.dsl.TargetFormat.Deb
            )
            packageName    = "MyApp"
            packageVersion = "1.0.0"
        }
    }
}
```

---

### `desktopApp/src/main/kotlin/main.kt` (optional)

```kotlin
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application

fun main() = application {
    Window(
        onCloseRequest = ::exitApplication,
        title          = "MyApp"
    ) {
        // App() lives in shared
        App()
    }
}
```

---

### `shared/src/commonMain/kotlin/<pkg>/App.kt`

```kotlin
package com.<yourpackage>

import androidx.compose.runtime.Composable

@Composable
fun App() {
    AppTheme {
        // AppNavigation() or first screen here
    }
}
```

---

## `gradle/libs.versions.toml`

> ⚠️ Use the `kmp-versions` skill to fill in real version numbers — do not hardcode from memory.

```toml
[versions]
# Fetch versions from official sources — see kmp-versions skill
kotlin               = "FETCH"
agp                  = "FETCH"
composeMultiplatform = "FETCH"
coroutines           = "FETCH"
serialization        = "FETCH"
lifecycle            = "FETCH"
android-compileSdk   = "35"
android-targetSdk    = "35"
android-minSdk       = "24"

[libraries]
# Compose Multiplatform — explicit declarations (compose.* accessors deprecated in CMP 1.10)
compose-runtime             = { module = "org.jetbrains.compose.runtime:runtime",                version.ref = "composeMultiplatform" }
compose-foundation          = { module = "org.jetbrains.compose.foundation:foundation",           version.ref = "composeMultiplatform" }
compose-ui                  = { module = "org.jetbrains.compose.ui:ui",                           version.ref = "composeMultiplatform" }
compose-material3           = { module = "org.jetbrains.compose.material3:material3",             version.ref = "composeMultiplatform" }
compose-material-icons-core = { module = "org.jetbrains.compose.material:material-icons-core",   version.ref = "composeMultiplatform" }
compose-ui-tooling-preview  = { module = "org.jetbrains.compose.ui:ui-tooling-preview",          version.ref = "composeMultiplatform" }

# Kotlin / KMP
kotlinx-coroutines-core    = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core",        version.ref = "coroutines" }
kotlinx-serialization-json = { module = "org.jetbrains.kotlinx:kotlinx-serialization-json",     version.ref = "serialization" }
lifecycle-viewmodel        = { module = "androidx.lifecycle:lifecycle-viewmodel",               version.ref = "lifecycle" }
kotlin-test                = { module = "org.jetbrains.kotlin:kotlin-test",                     version.ref = "kotlin" }

# Android
androidx-activity-compose = { module = "androidx.activity:activity-compose", version = "1.10.1" }

[plugins]
kotlinMultiplatform  = { id = "org.jetbrains.kotlin.multiplatform",           version.ref = "kotlin" }
androidApplication   = { id = "com.android.application",                      version.ref = "agp" }
# AGP 9+ new plugin for shared KMP library module
androidKmpLibrary    = { id = "com.android.kotlin.multiplatform.library",     version.ref = "agp" }
composeMultiplatform = { id = "org.jetbrains.compose",                        version.ref = "composeMultiplatform" }
composeCompiler      = { id = "org.jetbrains.kotlin.plugin.compose",          version.ref = "kotlin" }
kotlinSerialization  = { id = "org.jetbrains.kotlin.plugin.serialization",    version.ref = "kotlin" }
```

---

## DSL Migration: `androidTarget` → `android`

With Kotlin ≥ 2.3.0 and the `com.android.kotlin.multiplatform.library` plugin, the Android
target DSL block is renamed:

```kotlin
// ❌ Old — deprecated since Kotlin 2.3.0, warns; removed in future
kotlin {
    androidTarget {
        compilations.all { … }
    }
}

// ✅ New — use android {} when using com.android.kotlin.multiplatform.library
kotlin {
    android {
        compilations.all { … }
    }
}
```

---

## Source Set Naming

Source set names are unchanged — only the Gradle module structure changed:

| Source Set | Location in `shared/` | Contains |
|---|---|---|
| `commonMain` | `src/commonMain/kotlin/` | All shared business logic, shared UI, ViewModels |
| `androidMain` | `src/androidMain/kotlin/` | Android `actual` implementations, platform utils |
| `jvmMain` | `src/jvmMain/kotlin/` | Desktop `actual` implementations |
| `iosMain` | `src/iosMain/kotlin/` | iOS `actual` implementations |
| `commonTest` | `src/commonTest/kotlin/` | Shared unit tests |

---

## What Goes Where

| Code | Module | Source Set |
|---|---|---|
| `@Composable fun App()` | `shared` | `commonMain` |
| `AppTheme`, `MaterialTheme` | `shared` | `commonMain` |
| ViewModels, repositories, use-cases | `shared` | `commonMain` |
| `expect`/`actual` Platform APIs | `shared` | `commonMain` / `androidMain` / `jvmMain` |
| DI modules (Koin) | `shared` | `commonMain` (shared) + `androidMain`/`jvmMain` (platform) |
| Navigation (`NavHost`) | `shared` | `commonMain` |
| `MainActivity` (Android entry point) | `androidApp` | `main` |
| `main.kt` (Desktop entry point) | `desktopApp` | `main` |
| `Application` class (if Koin on Android) | `androidApp` | `main` |

---

## Migration Checklist (old → new structure)

- [ ] Create `shared/` module — move all `composeApp/src/` contents here
- [ ] Create `androidApp/` module — move `MainActivity` + `Application` here
- [ ] Update `shared/build.gradle.kts` — replace `com.android.library` with `com.android.kotlin.multiplatform.library`
- [ ] Rename `androidTarget {}` to `android {}` in `shared/build.gradle.kts`
- [ ] Update `androidApp/build.gradle.kts` — `com.android.application` only, depend on `:shared`
- [ ] Update `settings.gradle.kts` — include `:shared`, `:androidApp`, `:desktopApp`
- [ ] Remove `compose.*` plugin accessor shorthands — replace with `libs.*`
- [ ] Add `material-icons-core` explicitly (no longer transitive since CMP 1.8.2)
- [ ] Update all `import` statements for moved classes

---

## Official References

- [KMP Wizard](https://kmp.jetbrains.com/) — generates a valid project in the new structure
- [Android KMP Library Plugin](https://developer.android.com/kotlin/multiplatform/plugin)
- [AGP 9 Migration Guide](https://kotlinlang.org/docs/multiplatform/multiplatform-project-agp-9-migration.html)
- [KMP Compatibility Guide](https://kotlinlang.org/docs/multiplatform/multiplatform-compatibility-guide.html)
- [New Default KMP Structure (JetBrains Blog)](https://blog.jetbrains.com/kotlin/2026/05/new-kmp-default-structure/)
