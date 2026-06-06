---
name: kmp-versions
category: create-project
description: >
  Skill for resolving the correct, compatible set of versions for a Kotlin Multiplatform
  project. Instructs the AI to always fetch live version data from the official compatibility
  matrix instead of relying on its training data. Covers Kotlin/KGP, CMP, AGP, Gradle,
  and key library versions.
targets:
  - antigravity
  - claude
  - cursor
  - windsurf
sources:
  - https://kotlinlang.org/docs/multiplatform/multiplatform-compatibility-guide.html
  - https://kotlinlang.org/docs/gradle-configure-project.html
  - https://developer.android.com/kotlin/multiplatform/plugin
  - https://developer.android.com/build/releases/gradle-plugin
  - https://plugins.gradle.org/plugin/org.jetbrains.compose
---

# KMP Version Compatibility Skill

> **CRITICAL — AI VERSIONING WARNING**
>
> AI models have a training data cutoff and **will hallucinate stale or incompatible version
> numbers** for KMP projects if asked from memory. This skill exists to override that behavior.
>
> **You MUST follow the protocol below every time versions are needed for a KMP project.**
> Never generate a `libs.versions.toml` from memory alone.

---

## Protocol: How to Resolve Versions

When setting up or updating a KMP project, **always fetch live version data** using this
exact sequence. Do not skip steps.

### Step 1 — Fetch the official KGP compatibility matrix

Read this page to get the current Kotlin / Gradle / AGP compatibility table:

```
https://kotlinlang.org/docs/multiplatform/multiplatform-compatibility-guide.html
```

Extract the latest **stable** Kotlin version and its **maximum supported AGP and Gradle** versions.

### Step 2 — Confirm Compose Multiplatform version

Read the CMP releases page to find the latest stable CMP version compatible with the Kotlin
version from Step 1:

```
https://www.jetbrains.com/help/kotlin-multiplatform-dev/whats-new-compose.html
```

Or check the plugin portal for the latest published version:

```
https://plugins.gradle.org/plugin/org.jetbrains.compose
```

### Step 3 — Confirm AGP version

Check the Android Gradle Plugin release notes for the latest stable version:

```
https://developer.android.com/build/releases/gradle-plugin
```

Cross-check that the chosen AGP version falls within the KGP compatibility range from Step 1.

### Step 4 — Confirm Gradle wrapper version

Use the Gradle releases page to find the latest stable Gradle version within the KGP range:

```
https://gradle.org/releases/
```

### Step 5 — Confirm library versions

Check Maven Central or the official library repos for the latest stable versions:

| Library | Check URL |
|---|---|
| `kotlinx-coroutines` | https://github.com/Kotlin/kotlinx.coroutines/releases |
| `kotlinx-serialization` | https://github.com/Kotlin/kotlinx.serialization/releases |
| `androidx.lifecycle` | https://developer.android.com/jetpack/androidx/releases/lifecycle |
| `androidx.navigation` | https://developer.android.com/jetpack/androidx/releases/navigation |
| Koin | https://github.com/InsertKoinIO/koin/releases |
| Coil 3 | https://github.com/coil-kt/coil/releases |

---

## Compatibility Rules (always apply)

These rules are structural — they do not change with versions.

### Rule 1: Kotlin version = KGP version = composeCompiler plugin version

The Kotlin Gradle Plugin (KGP), the Compose compiler plugin, and the Kotlin stdlib all use the
**same version number**. They are always in sync.

```toml
kotlin = "2.x.x"  # One version for: KGP, composeCompiler plugin, kotlin-test
```

### Rule 2: AGP must be in the range for your Kotlin version

From the official matrix at `kotlinlang.org/docs/gradle-configure-project.html`:

| Kotlin | AGP min | AGP max |
|---|---|---|
| 2.4.0 | 8.5.2 | 9.1.0 |
| 2.3.20–2.3.21 | 8.2.2 | 9.0.0 |
| 2.3.0 | 8.2.2 | 8.13.0 |
| 2.2.20–2.2.21 | 7.3.1 | 8.11.1 |
| 2.1.20–2.1.21 | 7.3.1 | 8.7.2 |

> **Always verify this table from the live URL** — versions update regularly.

### Rule 3: Gradle wrapper must be in the range for your Kotlin version

| Kotlin | Gradle min | Gradle max |
|---|---|---|
| 2.4.0 | 7.6.3 | 9.5.0 |
| 2.3.20–2.3.21 | 7.6.3 | 9.3.0 |
| 2.2.20–2.2.21 | 7.6.3 | 8.14 |
| 2.1.20–2.1.21 | 7.6.3 | 8.12.1 |

### Rule 4: AGP ≥ 9.0 requires project restructure (see kmp-project-structure skill)

With AGP 9.0+, `com.android.application` and `com.android.library` **cannot coexist** with
`org.jetbrains.kotlin.multiplatform` in the same module. The project must use the new
`com.android.kotlin.multiplatform.library` plugin in the shared module and a separate
`androidApp` module for the app entry point.

### Rule 5: Compose Multiplatform version drives Compose library versions

All `org.jetbrains.compose.*` library versions must match the CMP plugin version exactly.
Never mix CMP library versions with a different CMP plugin version.

```toml
composeMultiplatform = "1.x.x"  # Plugin AND all org.jetbrains.compose.* libraries use this

compose-material3          = { module = "org.jetbrains.compose.material3:material3",            version.ref = "composeMultiplatform" }
compose-runtime            = { module = "org.jetbrains.compose.runtime:runtime",                version.ref = "composeMultiplatform" }
compose-ui                 = { module = "org.jetbrains.compose.ui:ui",                          version.ref = "composeMultiplatform" }
compose-foundation         = { module = "org.jetbrains.compose.foundation:foundation",          version.ref = "composeMultiplatform" }
compose-material-icons-core = { module = "org.jetbrains.compose.material:material-icons-core", version.ref = "composeMultiplatform" }
```

### Rule 6: Never use deprecated compose.* plugin accessor shorthands

Deprecated since CMP 1.10.0-beta01. Always use explicit `libs.*` references:

```kotlin
// ❌ Deprecated
implementation(compose.material3)
implementation(compose.ui)

// ✅ Correct
implementation(libs.compose.material3)
implementation(libs.compose.ui)
```

### Rule 7: material-icons-core is NOT transitive since CMP 1.8.2

Always declare it explicitly if you use any `Icons.*`:

```toml
compose-material-icons-core = { module = "org.jetbrains.compose.material:material-icons-core", version.ref = "composeMultiplatform" }
```

---

## Version Catalog Template

> ⚠️ **Fill in versions only after completing the 5-step protocol above.**
> Do not use the placeholder version numbers in this template as real versions.

```toml
[versions]
# ── Fetch from: kotlinlang.org/docs/multiplatform/multiplatform-compatibility-guide.html
kotlin               = "FETCH_FROM_OFFICIAL_SOURCE"

# ── Fetch from: developer.android.com/build/releases/gradle-plugin
# ── Must be in the AGP range for your Kotlin version
agp                  = "FETCH_FROM_OFFICIAL_SOURCE"

# ── Fetch from: plugins.gradle.org/plugin/org.jetbrains.compose
# ── Must be compatible with your Kotlin version
composeMultiplatform = "FETCH_FROM_OFFICIAL_SOURCE"

# ── Standard libraries — fetch latest stable from GitHub releases
coroutines           = "FETCH_FROM_OFFICIAL_SOURCE"
serialization        = "FETCH_FROM_OFFICIAL_SOURCE"

# ── Fetch from: developer.android.com/jetpack/androidx/releases/lifecycle
lifecycle            = "FETCH_FROM_OFFICIAL_SOURCE"

[libraries]
# Compose Multiplatform — explicit (compose.* accessors deprecated in CMP 1.10)
compose-runtime             = { module = "org.jetbrains.compose.runtime:runtime",                version.ref = "composeMultiplatform" }
compose-foundation          = { module = "org.jetbrains.compose.foundation:foundation",           version.ref = "composeMultiplatform" }
compose-ui                  = { module = "org.jetbrains.compose.ui:ui",                           version.ref = "composeMultiplatform" }
compose-material3           = { module = "org.jetbrains.compose.material3:material3",             version.ref = "composeMultiplatform" }
compose-material-icons-core = { module = "org.jetbrains.compose.material:material-icons-core",   version.ref = "composeMultiplatform" }
compose-ui-tooling-preview  = { module = "org.jetbrains.compose.ui:ui-tooling-preview",          version.ref = "composeMultiplatform" }

# Kotlin standard libraries
kotlinx-coroutines-core     = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core",        version.ref = "coroutines" }
kotlinx-serialization-json  = { module = "org.jetbrains.kotlinx:kotlinx-serialization-json",     version.ref = "serialization" }
lifecycle-viewmodel         = { module = "androidx.lifecycle:lifecycle-viewmodel",               version.ref = "lifecycle" }
kotlin-test                 = { module = "org.jetbrains.kotlin:kotlin-test",                     version.ref = "kotlin" }

[plugins]
kotlinMultiplatform  = { id = "org.jetbrains.kotlin.multiplatform",       version.ref = "kotlin" }
androidApplication   = { id = "com.android.application",                  version.ref = "agp" }
composeMultiplatform = { id = "org.jetbrains.compose",                    version.ref = "composeMultiplatform" }
composeCompiler      = { id = "org.jetbrains.kotlin.plugin.compose",      version.ref = "kotlin" }
kotlinSerialization  = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }

# Required for AGP 9.0+ projects (new project structure — see kmp-project-structure skill)
# androidKmpLibrary = { id = "com.android.kotlin.multiplatform.library", version.ref = "agp" }
```

---

## Gradle Wrapper

Set `distributionUrl` in `gradle/wrapper/gradle-wrapper.properties` to the **latest stable**
Gradle version **within the range for your Kotlin version**:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-X.X.X-bin.zip
```

Fetch the latest stable from: https://gradle.org/releases/

---

## Known Breaking Changes (version-gated)

| From → To | Breaking Change | Action |
|---|---|---|
| Any → CMP 1.8.2 | `material-icons-core` no longer transitive | Add explicitly to toml |
| Any → CMP 1.10 | `compose.*` plugin accessors deprecated | Use `libs.*` references |
| Any → Kotlin 2.3.0 | `androidTarget {}` block deprecated → warn | Rename to `android {}` (use new plugin) |
| Any → Kotlin 2.2.0 | `android {}` DSL removed from KMP plugin | Must use `com.android.kotlin.multiplatform.library` |
| Any → AGP 9.0 | `com.android.library` incompatible with KMP plugin | Restructure project; separate androidApp module |
| Any → Kotlin 2.1.20 | `withJava()` deprecated | Remove it; Java source sets created automatically |
| Any → Kotlin 2.2.0 | `ios()`, `watchos()`, `tvos()` shortcuts removed | Use explicit targets: `iosArm64()`, `iosSimulatorArm64()` |

---

## Official Sources (always use these — do not rely on AI memory)

| Resource | URL |
|---|---|
| **KMP Compatibility Matrix** (Kotlin / Gradle / AGP / Xcode) | https://kotlinlang.org/docs/multiplatform/multiplatform-compatibility-guide.html |
| **KGP + Gradle + AGP table** | https://kotlinlang.org/docs/gradle-configure-project.html |
| **CMP Releases & What's New** | https://www.jetbrains.com/help/kotlin-multiplatform-dev/whats-new-compose.html |
| **AGP Release Notes** | https://developer.android.com/build/releases/gradle-plugin |
| **Gradle Releases** | https://gradle.org/releases/ |
| **KMP Wizard (generates a valid project)** | https://kmp.jetbrains.com/ |
| **Coroutines** | https://github.com/Kotlin/kotlinx.coroutines/releases |
| **Serialization** | https://github.com/Kotlin/kotlinx.serialization/releases |
| **Lifecycle** | https://developer.android.com/jetpack/androidx/releases/lifecycle |
| **Koin** | https://github.com/InsertKoinIO/koin/releases |
| **Navigation Compose** | https://developer.android.com/jetpack/androidx/releases/navigation |
| **Coil 3** | https://github.com/coil-kt/coil/releases |
