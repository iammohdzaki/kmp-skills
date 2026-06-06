---
name: material3-design-system
category: design-system
description: >
  Comprehensive Material 3 (Material You) design system skill for Jetpack Compose
  and Compose Multiplatform (KMP). Covers color tokens, typography, shape, 30+
  components, adaptive layout, navigation patterns, dynamic color, dark mode,
  motion/animation, and accessibility. Compose-first — no web or Flutter code.
targets:
  - antigravity
  - claude
  - cursor
  - windsurf
argument-hint: "[component|theme|layout|navigation|audit] [description, file path, or screen name]"
sources:
  - https://m3.material.io/
  - https://developer.android.com/develop/ui/compose/designsystems/material3
  - https://m3.material.io/blog/whats-new-at-io26
  - https://github.com/hamen/material-3-skill
---

# Material Design 3 — KMP / Compose Multiplatform Skill

This skill guides implementation of Google's **Material Design 3 (MD3 / Material You)** using
**Jetpack Compose** and **Compose Multiplatform** for KMP projects (Android + Desktop).

> **Attribution**: This skill is adapted from and gives credit to
> **[hamen/material-3-skill](https://github.com/hamen/material-3-skill)** by Hamen.
> The original skill covers web and Flutter targets. This KMP edition strips all web/CSS/Flutter
> patterns and replaces them with pure Compose Multiplatform APIs, adds the audit report system,
> and extends the reference set for adaptive layout, navigation, and versioning.

> **Scope**: Compose-only. All examples use `androidx.compose.material3` APIs — the same API
> surface is available in KMP `commonMain` via `org.jetbrains.compose.material3:material3`
> (declared explicitly in `libs.versions.toml`). No web CSS, no `@material/web` elements, no Flutter.

---

## MD3 Philosophy

| Principle | What it means in Compose |
|---|---|
| **Personal** | Dynamic color from user wallpaper (Android 12+). Static fallback for Desktop. |
| **Adaptive** | `WindowSizeClass` drives layout changes across compact → expanded screens. |
| **Expressive** | Spring-based motion, shape morphing, emphasized typography. |

### Google I/O 2026 Key Updates

- **Compose-first on Android**: For all new Android work, use `androidx.compose.material3`.
- **Expressive layout scaffold**: Design screens to adapt across mobile, desktop, foldables. Use `Material3Adaptive` scaffold APIs.
- **8dp spacing system**: Define spacing as tokens — never scatter raw `Dp` literals.
- **New expressive components**: Lists, menus, search, and search app bars have refreshed expressive guidance; check your Material3 BOM for expressive variants.

---

## Design Token System

All MD3 values come through `MaterialTheme`. **Never hardcode** raw values inline.

| Token category | Access in Compose |
|---|---|
| Color | `MaterialTheme.colorScheme.*` |
| Typography | `MaterialTheme.typography.*` |
| Shape | `MaterialTheme.shapes.*` |
| Spacing | Define a `Dimens` object (no built-in API) |

---

## Decision Tree

```
What are you building?

Full app scaffold        → AppTheme setup + references/theming-and-dynamic-color.md
Single component         → references/component-catalog.md
Custom color theme       → references/color-system.md
Typography / fonts       → references/typography-and-shape.md
Navigation structure     → references/navigation-patterns.md
Adaptive layout          → references/layout-and-responsive.md
```

---

## Color Token Summary

Full details in [references/color-system.md](references/color-system.md).

### Key Roles (Compose token → usage)

| Role | Token | Primary Usage |
|---|---|---|
| Primary | `colorScheme.primary` | FAB, key buttons, active states |
| On Primary | `colorScheme.onPrimary` | Text/icons on primary |
| Primary Container | `colorScheme.primaryContainer` | Tonal buttons, selected chips |
| On Primary Container | `colorScheme.onPrimaryContainer` | Text on primary container |
| Secondary | `colorScheme.secondary` | Less prominent accents, filters |
| Secondary Container | `colorScheme.secondaryContainer` | Recessive fills |
| Tertiary | `colorScheme.tertiary` | Contrasting accent sections |
| Surface | `colorScheme.surface` | Cards, sheets, menus |
| Surface Container | `colorScheme.surfaceContainer` | Navigation areas |
| On Surface | `colorScheme.onSurface` | Body text, icons |
| On Surface Variant | `colorScheme.onSurfaceVariant` | Placeholder, helper text |
| Outline | `colorScheme.outline` | Input borders, dividers |
| Error | `colorScheme.error` | Error states |

---

## Typography Token Summary

Full details in [references/typography-and-shape.md](references/typography-and-shape.md).

| Category | Styles | Usage |
|---|---|---|
| Display | L / M / S | Hero text, large numbers |
| Headline | L / M / S | Screen/section headers |
| Title | L / M / S | Toolbar titles, card headers |
| Body | L / M / S | Paragraph text, descriptions |
| Label | L / M / S | Buttons, chips, captions |

```kotlin
// ✅ Always via MaterialTheme
Text("Title", style = MaterialTheme.typography.titleLarge)
Text("Body", style = MaterialTheme.typography.bodyMedium)

// ❌ Never inline
Text("Title", fontSize = 22.sp, fontWeight = FontWeight.Normal)
```

---

## Shape Token Summary

| Token | Corner Radius | Typical Components |
|---|---|---|
| `shapes.extraSmall` | 4dp | Chips, snackbars |
| `shapes.small` | 8dp | Text fields, menus |
| `shapes.medium` | 12dp | Cards |
| `shapes.large` | 16dp | FABs, nav drawer |
| `shapes.extraLarge` | 28dp | Dialogs, bottom sheets |

---

## Elevation

MD3 communicates depth through **tonal surface color**, not drop shadows.

| Level | Compose API | Tonal Offset | Use |
|---|---|---|---|
| 0 | `Elevation.Level0` / `0.dp` | None | Flat surfaces at rest |
| 1 | `Elevation.Level1` / `1.dp` | +5% primary | Elevated cards |
| 2 | `Elevation.Level2` / `3.dp` | +8% primary | Menus, nav bar |
| 3 | `Elevation.Level3` / `6.dp` | +11% primary | FAB, dialogs |

```kotlin
// Cards respect tonal elevation automatically via surfaceTonalElevation
ElevatedCard(elevation = CardDefaults.elevatedCardElevation(defaultElevation = 6.dp)) { }
```

---

## Motion Summary

Full details in [references/typography-and-shape.md](references/typography-and-shape.md) §Motion.

| Easing | Compose | Usage |
|---|---|---|
| Emphasized | `CubicBezierEasing(0.2f, 0f, 0f, 1f)` | Elements staying on screen |
| Emphasized Decelerate | `CubicBezierEasing(0.05f, 0.7f, 0.1f, 1f)` | Entering screen |
| Emphasized Accelerate | `CubicBezierEasing(0.3f, 0f, 0.8f, 0.15f)` | Leaving screen |
| Standard | `FastOutSlowInEasing` | Utility animations |

### Standard Durations

| Token | Duration | Usage |
|---|---|---|
| Short | 100–200ms | Icon/color state changes |
| Medium | 300–400ms | Component expand/collapse |
| Long | 400–500ms | Screen-level transitions |

---

## Component Quick Reference

| Component | Compose API | Category |
|---|---|---|
| Button (Filled) | `Button {}` | Actions |
| Button (Tonal) | `FilledTonalButton {}` | Actions |
| Button (Outlined) | `OutlinedButton {}` | Actions |
| Button (Text) | `TextButton {}` | Actions |
| FAB | `FloatingActionButton {}` | Actions |
| Extended FAB | `ExtendedFloatingActionButton {}` | Actions |
| Icon Button | `IconButton {}`, `FilledIconButton {}` | Actions |
| Segmented Button | `SegmentedButton {}` | Actions |
| Card | `Card {}`, `ElevatedCard {}`, `OutlinedCard {}` | Containment |
| Dialog | `AlertDialog {}`, `Dialog {}` | Containment |
| Bottom Sheet | `ModalBottomSheet {}` | Sheets |
| Snackbar | `SnackbarHost {}` | Communication |
| Progress | `CircularProgressIndicator()`, `LinearProgressIndicator()` | Communication |
| Badge | `BadgedBox {}` | Communication |
| Checkbox | `Checkbox()` | Input |
| RadioButton | `RadioButton()` | Input |
| Switch | `Switch()` | Input |
| Slider | `Slider()`, `RangeSlider()` | Input |
| TextField | `TextField()`, `OutlinedTextField()` | Input |
| Chips | `FilterChip`, `AssistChip`, `InputChip`, `SuggestionChip` | Input |
| TopAppBar | `TopAppBar`, `CenterAlignedTopAppBar`, `LargeTopAppBar` | Navigation |
| Navigation Bar | `NavigationBar {}` | Navigation |
| Navigation Rail | `NavigationRail {}` | Navigation |
| Navigation Drawer | `ModalNavigationDrawer {}` | Navigation |
| Tabs | `TabRow {}`, `ScrollableTabRow {}` | Navigation |

Full Compose API + examples: [references/component-catalog.md](references/component-catalog.md)

---

## AppTheme Setup (Quick Start)

```kotlin
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // Dynamic color is Android 12+ only — always falls back to static on Desktop
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else      -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography  = AppTypography,
        shapes      = AppShapes,
        content     = content
    )
}
```

> For **Compose Multiplatform Desktop**: Remove `Build.VERSION_SDK_INT` check and always use
> `LightColorScheme` / `DarkColorScheme`. Dynamic color has no JVM equivalent.

Full theming guide: [references/theming-and-dynamic-color.md](references/theming-and-dynamic-color.md)

---

## Core Rules

- **Never** hardcode `Color(0xFF...)` in composables — always `MaterialTheme.colorScheme.*`
- **Never** inline `fontSize`, `fontFamily`, `fontWeight` — always `MaterialTheme.typography.*`
- **Never** inline `RoundedCornerShape(12.dp)` — always `MaterialTheme.shapes.*`
- **Always** wrap content in `AppTheme` at the root — never in individual screens
- **Always** support dark mode — test every screen with `isSystemInDarkTheme()`
- **Always** use `Scaffold` — it handles `topBar`, `bottomBar`, `FAB`, `snackbarHost`, padding
- Minimum touch target: **48×48dp** for all interactive elements
- Spacing tokens: **always multiples of 4dp** — define a `Dimens` object
- For Desktop/JVM: always use static color schemes — no dynamic color API on JVM

---

## MD3 Compliance Audit

When the user asks for an **audit**, a **compliance check**, or passes code / a screen name
with the `audit` argument, run a full MD3 compliance report using the template below.

### How to trigger

```
audit [screen name or paste code here]
audit HomeScreen
audit <paste composable code>
check this screen against material 3
run md3 audit
```

### Audit Process

1. **Scan the target** — read the provided code or ask the user to paste the composable(s) to audit.
2. **Check each category** below in order.
3. **Output the report** using the exact format specified.
4. **Offer fixes** — for every ❌ or ⚠️, provide the corrected Compose code snippet inline.

---

### Audit Report Format

Output the report in this exact structure:

```
╔══════════════════════════════════════════════════════════╗
║          MD3 COMPLIANCE AUDIT — [Screen/File Name]       ║
║          KMP / Compose Multiplatform Edition             ║
╚══════════════════════════════════════════════════════════╝

Score: [X / 10]   Grade: [A / B / C / D / F]

┌─────────────────────────────────────────────────────────┐
│ CATEGORY RESULTS                                        │
└─────────────────────────────────────────────────────────┘

[✅ / ⚠️ / ❌]  COLOR SYSTEM          [PASS / WARN / FAIL]
[✅ / ⚠️ / ❌]  TYPOGRAPHY            [PASS / WARN / FAIL]
[✅ / ⚠️ / ❌]  SHAPE                 [PASS / WARN / FAIL]
[✅ / ⚠️ / ❌]  SPACING               [PASS / WARN / FAIL]
[✅ / ⚠️ / ❌]  ELEVATION             [PASS / WARN / FAIL]
[✅ / ⚠️ / ❌]  COMPONENTS            [PASS / WARN / FAIL]
[✅ / ⚠️ / ❌]  LAYOUT & ADAPTIVE     [PASS / WARN / FAIL]
[✅ / ⚠️ / ❌]  NAVIGATION            [PASS / WARN / FAIL]
[✅ / ⚠️ / ❌]  MOTION & ANIMATION    [PASS / WARN / FAIL]
[✅ / ⚠️ / ❌]  DARK MODE             [PASS / WARN / FAIL]
[✅ / ⚠️ / ❌]  ACCESSIBILITY         [PASS / WARN / FAIL]
[✅ / ⚠️ / ❌]  THEMING SETUP         [PASS / WARN / FAIL]

┌─────────────────────────────────────────────────────────┐
│ FINDINGS                                                │
└─────────────────────────────────────────────────────────┘

[findings listed per category — see check rules below]

┌─────────────────────────────────────────────────────────┐
│ FIXES                                                   │
└─────────────────────────────────────────────────────────┘

[corrected code snippets for every ❌ and ⚠️]
```

---

### Audit Check Rules — Per Category

#### 1. COLOR SYSTEM

| Check | Pass condition | Fail condition |
|---|---|---|
| No hardcoded colors in composables | `MaterialTheme.colorScheme.*` used | `Color(0xFF…)` literal in UI code |
| No swapped semantic roles | `error` used for errors only | `error` used for success/warning |
| Both schemes defined | `LightColorScheme` + `DarkColorScheme` exist | Only one scheme present |
| Dynamic color has static fallback | `if (dynamicColor && SDK >= S)` with else branch | Dynamic color used unconditionally |
| Extended colors use `CompositionLocal` | `LocalExtendedColors` pattern | Raw color passed as parameter |
| Desktop: no dynamic color API | `jvmMain` uses static scheme | `dynamicDarkColorScheme()` in `jvmMain` |

#### 2. TYPOGRAPHY

| Check | Pass condition | Fail condition |
|---|---|---|
| No inline font sizes | `MaterialTheme.typography.*` used | `fontSize = 16.sp` inline |
| No inline font weights | `MaterialTheme.typography.*` used | `fontWeight = FontWeight.Bold` inline |
| Custom font loaded via `Res.font.*` | `Font(Res.font.*)` for KMP | Hardcoded path or `fontFamily` literal |
| All 15 styles defined if custom typography | `Typography(displayLarge = …, labelSmall = …)` | Missing styles in custom `Typography` |
| Body text uses `bodyLarge`/`bodyMedium` | Correct role applied | `displayLarge` on body copy |

#### 3. SHAPE

| Check | Pass condition | Fail condition |
|---|---|---|
| No inline `RoundedCornerShape` | `MaterialTheme.shapes.*` used | `RoundedCornerShape(12.dp)` inline |
| Shape token matches component | Cards use `shapes.medium`, FABs use `shapes.extraLarge` | FAB with `shapes.small` |
| Custom shapes defined in `AppShapes` | `val AppShapes = Shapes(…)` in theme | Shape overrides scattered in UI |

#### 4. SPACING

| Check | Pass condition | Fail condition |
|---|---|---|
| Spacing uses `Dimens` object | `Dimens.md`, `Dimens.lg`, etc. | Scattered `16.dp`, `24.dp` literals |
| Values are multiples of 4dp | 4, 8, 12, 16, 24, 32, 48dp | 15.dp, 7.dp, 11.dp literals |
| Screen margins consistent | `Dimens.screenHorizontal` used | Mixed margin values per screen |

#### 5. ELEVATION

| Check | Pass condition | Fail condition |
|---|---|---|
| Tonal elevation used | `tonalElevation` / `CardDefaults.elevatedCardElevation()` | `Modifier.shadow(8.dp)` for depth |
| Shadow used only for busy backgrounds | Rare `Modifier.shadow` with clear reason | Shadows on all cards for styling |

#### 6. COMPONENTS

| Check | Pass condition | Fail condition |
|---|---|---|
| Only one `Button` (filled) per section | Single primary action | Multiple filled buttons per section |
| FAB in `Scaffold.floatingActionButton` | `Scaffold(floatingActionButton = {…})` | FAB positioned manually with `Box` |
| `Scaffold` used on every screen | `Scaffold {}` wraps each screen | No `Scaffold`, manual layout |
| `AlertDialog` for destructive actions | `confirmButton` + `dismissButton` both present | No dismiss option on destructive dialog |
| Lists use `ListItem` | `ListItem(headlineContent = …)` | Custom `Row` replacing `ListItem` |
| Buttons use correct emphasis hierarchy | Filled → Tonal → Elevated → Outlined → Text | Multiple filled buttons, no hierarchy |

#### 7. LAYOUT & ADAPTIVE

| Check | Pass condition | Fail condition |
|---|---|---|
| `WindowSizeClass` used | `calculateWindowSizeClass()` or `currentWindowAdaptiveInfo()` | Fixed-width `if (isTablet)` hack |
| No hardcoded breakpoints | `WindowWidthSizeClass.*` enum | `if (width > 600.dp)` check |
| Canonical layout pattern used | Feed / List-Detail / Supporting Pane | None of the canonical patterns applied |
| Edge-to-edge enabled | `enableEdgeToEdge()` in Activity | Status bar not handled |
| `WindowInsets` applied | `Modifier.statusBarsPadding()` or `Scaffold` | Content hidden behind system bars |
| Adaptive API used for list-detail | `NavigableListDetailPaneScaffold` | Manual `Row` reimplementing list-detail |

#### 8. NAVIGATION

| Check | Pass condition | Fail condition |
|---|---|---|
| Nav component matches window size | `NavigationBar` on compact, `NavigationRail` on medium, drawer on expanded | Bottom nav on tablet |
| Bottom nav has 3–5 items | Destination count in range | 2 or 6+ items in `NavigationBar` |
| `launchSingleTop = true` | Present on all nav clicks | Duplicate back-stack entries possible |
| `saveState + restoreState` | Present on nav clicks | Tab scroll position lost |
| Type-safe routes | `@Serializable` objects/classes | String literal routes |
| `NavController` not in ViewModel | Navigate via `UiEffect` | `navController` injected into ViewModel |

#### 9. MOTION & ANIMATION

| Check | Pass condition | Fail condition |
|---|---|---|
| Easing matches direction | Entering: `EmphasizedDecelerate`, Leaving: `EmphasizedAccelerate` | Symmetric easing for enter/exit |
| `animate*AsState` has `label =` | `label = "colorAnimation"` present | Missing `label` parameter |
| Duration ≤ 500ms screen, ≤ 300ms component | Within limits | `tween(800ms)` on a button |
| Spring for interactions, tween for transitions | `spring()` on drag/toggle, `tween()` on nav | `tween()` on swipe gesture |

#### 10. DARK MODE

| Check | Pass condition | Fail condition |
|---|---|---|
| `isSystemInDarkTheme()` wired to theme | `darkTheme = isSystemInDarkTheme()` | Hard-coded `darkTheme = false` |
| Both schemes tested | Code has `DarkColorScheme` defined | Only `LightColorScheme` present |
| `@Preview(uiMode = UI_MODE_NIGHT_YES)` on previews | Both light and dark previews | Only light mode previews |

#### 11. ACCESSIBILITY

| Check | Pass condition | Fail condition |
|---|---|---|
| Touch targets ≥ 48×48dp | Icons/buttons have `Modifier.size(48.dp)` or larger | `Modifier.size(24.dp)` as only modifier on clickable |
| Icon-only buttons have `contentDescription` | Non-null description | `contentDescription = null` on icon button |
| Contrast ratio ≥ 4.5:1 (normal text) | M3 baseline palette used | Custom palette not validated |
| No color-only state communication | Icon/text also changes state | Only color changes for selected state |
| Semantic roles applied | `Modifier.semantics { role = Role.Button }` where needed | Custom clickable without role |

#### 12. THEMING SETUP

| Check | Pass condition | Fail condition |
|---|---|---|
| Single `MaterialTheme` call at root | `AppTheme` wraps root composable only | `MaterialTheme` called in individual screens |
| `AppTheme` has `darkTheme` + `dynamicColor` params | Both parameters present | Theme has no parameters |
| `AppTypography`, `AppShapes` defined | Separate files in `theme/` | Defaults used (`MaterialTheme()` with no args) |
| Desktop uses `expect`/`actual` for theme | `rememberColorScheme` split across source sets | Android-only dynamic color call in `commonMain` |

---

### Scoring

| Score | Grade | Meaning |
|---|---|---|
| 10 / 10 | **A** | Full MD3 compliance — production ready |
| 8–9 / 10 | **B** | Minor warnings — good with small fixes |
| 6–7 / 10 | **C** | Several violations — needs attention |
| 4–5 / 10 | **D** | Major issues — significant rework needed |
| 0–3 / 10 | **F** | Critical violations — MD3 not followed |

Each category scores 1 point: **✅ PASS = 1pt**, **⚠️ WARN = 0.5pt**, **❌ FAIL = 0pt**.
Round to nearest 0.5.

---

## Reference Files

| File | Contents |
|---|---|
| [references/color-system.md](references/color-system.md) | All 29 color roles, light/dark schemes, dynamic color, custom extensions |
| [references/theming-and-dynamic-color.md](references/theming-and-dynamic-color.md) | AppTheme setup, dynamic color, KMP (Android+Desktop) theme split |
| [references/typography-and-shape.md](references/typography-and-shape.md) | Full 15-style type scale, font setup, shape tokens, elevation, motion |
| [references/component-catalog.md](references/component-catalog.md) | All 30+ components with Compose API + code examples |
| [references/layout-and-responsive.md](references/layout-and-responsive.md) | WindowSizeClass, adaptive scaffolds, canonical layouts, spacing tokens |
| [references/navigation-patterns.md](references/navigation-patterns.md) | NavBar, Rail, Drawer, Tabs — when to use each, Compose wiring |

---

## Dependencies

### ⚠️ Deprecation: plugin accessor shorthands

The `compose.material3`, `compose.ui`, `compose.foundation` **shorthand accessors** previously
provided by the Compose Multiplatform Gradle plugin are **deprecated as of CMP 1.10.0-beta01**.

| Old (deprecated) | New (explicit libs entry) |
|---|---|
| `implementation(compose.material3)` | `implementation(libs.compose.material3)` |
| `implementation(compose.ui)` | `implementation(libs.compose.ui)` |
| `implementation(compose.foundation)` | `implementation(libs.compose.foundation)` |

### ⚠️ Breaking: `material-icons-core` is no longer transitive (since CMP 1.8.2)

Starting with CMP 1.8.2, the implicit dependency on `material-icons-core` was removed.
If your project uses `Icons.Default.*` or any Material icon, add it **explicitly**.

### `gradle/libs.versions.toml`

```toml
[versions]
kotlin               = "2.1.21"
agp                  = "8.10.0"
composeMultiplatform = "1.8.2"   # org.jetbrains.compose plugin version
coroutines           = "1.10.2"
lifecycle            = "2.9.0"

[libraries]
# ✅ Correct module for commonMain
# The CMP plugin maps this → androidx.compose.material3 on Android automatically
compose-material3          = { module = "org.jetbrains.compose.material3:material3",            version.ref = "composeMultiplatform" }
compose-runtime            = { module = "org.jetbrains.compose.runtime:runtime",                version.ref = "composeMultiplatform" }
compose-foundation         = { module = "org.jetbrains.compose.foundation:foundation",          version.ref = "composeMultiplatform" }
compose-ui                 = { module = "org.jetbrains.compose.ui:ui",                          version.ref = "composeMultiplatform" }
# Declare explicitly — no longer a transitive dep since CMP 1.8.2
compose-material-icons-core = { module = "org.jetbrains.compose.material:material-icons-core", version.ref = "composeMultiplatform" }
compose-ui-tooling-preview  = { module = "org.jetbrains.compose.ui:ui-tooling-preview",        version.ref = "composeMultiplatform" }

[plugins]
kotlinMultiplatform  = { id = "org.jetbrains.kotlin.multiplatform",       version.ref = "kotlin" }
androidApplication   = { id = "com.android.application",                  version.ref = "agp" }
composeMultiplatform = { id = "org.jetbrains.compose",                    version.ref = "composeMultiplatform" }
composeCompiler      = { id = "org.jetbrains.kotlin.plugin.compose",      version.ref = "kotlin" }
```

### `composeApp/build.gradle.kts`

```kotlin
kotlin {
    sourceSets {
        commonMain.dependencies {
            // ✅ Use libs.* — NOT the deprecated compose.* plugin accessors
            implementation(libs.compose.runtime)
            implementation(libs.compose.foundation)
            implementation(libs.compose.ui)
            implementation(libs.compose.material3)
            implementation(libs.compose.material.icons.core)  // explicit since CMP 1.8.2
        }
        androidMain.dependencies {
            implementation(libs.compose.ui.tooling.preview)
        }
    }
}
```

### Module mapping (how it works)

| Source set | Module in toml | What Gradle actually resolves |
|---|---|---|
| `commonMain` | `org.jetbrains.compose.material3:material3` | JetBrains multiplatform artifact |
| `androidMain` (via CMP plugin metadata) | same toml entry | `androidx.compose.material3:material3` |
| `jvmMain` (Desktop) | same toml entry | JetBrains desktop artifact |

You **never** need to manually switch to `androidx.compose.material3` in build files —
the CMP Gradle plugin metadata handles the platform mapping transparently.

---

## Official Docs

- [Material 3](https://m3.material.io/)
- [Compose Material 3](https://developer.android.com/develop/ui/compose/designsystems/material3)
- [M3 Theme Builder](https://material-foundation.github.io/material-theme-builder/)
- [Compose Multiplatform](https://www.jetbrains.com/compose-multiplatform/)
- [Material3 Adaptive](https://developer.android.com/jetpack/androidx/releases/compose-material3-adaptive)
- [CMP Release Notes](https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-multiplatform-releases.html)
