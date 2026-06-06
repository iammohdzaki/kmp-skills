# MD3 Typography, Shape, Elevation, and Motion — Compose / KMP

Reference for Material Design 3's visual token systems in **Jetpack Compose** and
**Compose Multiplatform**.

---

## Typography

### Type Scale

MD3 defines **15 baseline styles** + **15 emphasized styles** in 5 categories × 3 sizes.
Access via `MaterialTheme.typography.*`.

#### Baseline Type Scale

| Style | Token | Weight | Size | Line Height | Tracking | Usage |
|---|---|---|---|---|---|---|
| Display Large | `typography.displayLarge` | 400 | 57sp | 64sp | -0.25sp | Hero text, large numbers |
| Display Medium | `typography.displayMedium` | 400 | 45sp | 52sp | 0sp | Feature callouts |
| Display Small | `typography.displaySmall` | 400 | 36sp | 44sp | 0sp | Large onboarding text |
| Headline Large | `typography.headlineLarge` | 400 | 32sp | 40sp | 0sp | Screen titles (rare) |
| Headline Medium | `typography.headlineMedium` | 400 | 28sp | 36sp | 0sp | Dialog titles, section headers |
| Headline Small | `typography.headlineSmall` | 400 | 24sp | 32sp | 0sp | Card headers |
| Title Large | `typography.titleLarge` | 400 | 22sp | 28sp | 0sp | TopAppBar title |
| Title Medium | `typography.titleMedium` | 500 | 16sp | 24sp | 0.15sp | List item titles |
| Title Small | `typography.titleSmall` | 500 | 14sp | 20sp | 0.1sp | Nav drawer items |
| Body Large | `typography.bodyLarge` | 400 | 16sp | 24sp | 0.5sp | Primary body text |
| Body Medium | `typography.bodyMedium` | 400 | 14sp | 20sp | 0.25sp | Secondary body text |
| Body Small | `typography.bodySmall` | 400 | 12sp | 16sp | 0.4sp | Supporting text, help text |
| Label Large | `typography.labelLarge` | 500 | 14sp | 20sp | 0.1sp | **Buttons**, prominent labels |
| Label Medium | `typography.labelMedium` | 500 | 12sp | 16sp | 0.5sp | Chips, tabs, badges |
| Label Small | `typography.labelSmall` | 500 | 11sp | 16sp | 0.5sp | Overlines, captions |

#### Emphasized Styles (Expressive, M3 2025+)

Emphasized styles mirror the baseline but with higher weight. Use for:
- Selected/active states
- Primary action labels
- Headlines needing emphasis
- Unread/important content markers

Apply by boosting `fontWeight` in your `TextStyle`:
```kotlin
// Emphasized variant — increase weight by one step
val titleLargeEmphasized = MaterialTheme.typography.titleLarge.copy(
    fontWeight = FontWeight.Medium  // baseline is Regular
)
```

---

## Setting Up Custom Typography

### Step 1: Add font files

Place fonts in `composeApp/src/commonMain/composeResources/font/`:
```
font/
├── inter_light.ttf
├── inter_regular.ttf
├── inter_medium.ttf
└── inter_bold.ttf
```

### Step 2: Build the FontFamily and Typography

```kotlin
// theme/AppTypography.kt
import org.jetbrains.compose.resources.Font

@Composable
fun rememberAppTypography(): Typography {
    val fontFamily = FontFamily(
        Font(Res.font.inter_light,   FontWeight.Light),
        Font(Res.font.inter_regular, FontWeight.Normal),
        Font(Res.font.inter_medium,  FontWeight.Medium),
        Font(Res.font.inter_bold,    FontWeight.Bold),
    )

    return Typography(
        displayLarge  = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Light,  fontSize = 57.sp,  lineHeight = 64.sp, letterSpacing = (-0.25).sp),
        displayMedium = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Light,  fontSize = 45.sp,  lineHeight = 52.sp, letterSpacing = 0.sp),
        displaySmall  = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Normal, fontSize = 36.sp,  lineHeight = 44.sp, letterSpacing = 0.sp),
        headlineLarge  = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Normal, fontSize = 32.sp, lineHeight = 40.sp, letterSpacing = 0.sp),
        headlineMedium = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Normal, fontSize = 28.sp, lineHeight = 36.sp, letterSpacing = 0.sp),
        headlineSmall  = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Normal, fontSize = 24.sp, lineHeight = 32.sp, letterSpacing = 0.sp),
        titleLarge  = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Normal, fontSize = 22.sp, lineHeight = 28.sp, letterSpacing = 0.sp),
        titleMedium = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Medium, fontSize = 16.sp, lineHeight = 24.sp, letterSpacing = 0.15.sp),
        titleSmall  = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Medium, fontSize = 14.sp, lineHeight = 20.sp, letterSpacing = 0.1.sp),
        bodyLarge  = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Normal, fontSize = 16.sp, lineHeight = 24.sp, letterSpacing = 0.5.sp),
        bodyMedium = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Normal, fontSize = 14.sp, lineHeight = 20.sp, letterSpacing = 0.25.sp),
        bodySmall  = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Normal, fontSize = 12.sp, lineHeight = 16.sp, letterSpacing = 0.4.sp),
        labelLarge  = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Medium, fontSize = 14.sp, lineHeight = 20.sp, letterSpacing = 0.1.sp),
        labelMedium = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Medium, fontSize = 12.sp, lineHeight = 16.sp, letterSpacing = 0.5.sp),
        labelSmall  = TextStyle(fontFamily = fontFamily, fontWeight = FontWeight.Medium, fontSize = 11.sp, lineHeight = 16.sp, letterSpacing = 0.5.sp),
    )
}
```

### Step 3: Apply in AppTheme

```kotlin
@Composable
fun AppTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val typography = rememberAppTypography()
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme,
        typography  = typography,
        shapes      = AppShapes,
        content     = content
    )
}
```

### Usage

```kotlin
Text("Screen Title",  style = MaterialTheme.typography.titleLarge)
Text("Description",   style = MaterialTheme.typography.bodyMedium)
Text("Helper text",   style = MaterialTheme.typography.bodySmall,
     color = MaterialTheme.colorScheme.onSurfaceVariant)
// Buttons apply labelLarge automatically — don't override
```

### Recommended Fonts for KMP

| Font | Character | Weights |
|---|---|---|
| **Inter** | Clean, modern, excellent readability | 100–900 |
| **Roboto** | Android default, M3 baseline font | 100–900 |
| **DM Sans** | Friendly, geometric | 200–700 |
| **Outfit** | Contemporary, versatile | 100–900 |
| **Plus Jakarta Sans** | Premium, professional | 200–800 |

---

## Shape System

MD3 defines 5 shape tokens. Use `MaterialTheme.shapes.*` — never inline `RoundedCornerShape`.

```kotlin
// theme/AppShapes.kt
val AppShapes = Shapes(
    extraSmall = RoundedCornerShape(4.dp),
    small      = RoundedCornerShape(8.dp),
    medium     = RoundedCornerShape(12.dp),
    large      = RoundedCornerShape(16.dp),
    extraLarge = RoundedCornerShape(28.dp),
)
```

| Token | Radius | Typical Components |
|---|---|---|
| `shapes.extraSmall` | 4dp | Tooltips, small chips, snackbars |
| `shapes.small` | 8dp | Text fields, menus, filled buttons |
| `shapes.medium` | 12dp | Cards, menus, dialogs |
| `shapes.large` | 16dp | Bottom sheets, large cards, nav drawer |
| `shapes.extraLarge` | 28dp | FABs, extended FABs |

### Usage

```kotlin
// ✅ Correct — from theme
Card(shape = MaterialTheme.shapes.medium) { }
Surface(shape = MaterialTheme.shapes.extraLarge) { }

// ❌ Wrong — hardcoded
Card(shape = RoundedCornerShape(12.dp)) { }
```

### Expressive Shapes (M3 2025+)

Expressive variants add additional shape tokens between existing levels:
- `large-increased` ≈ 20dp
- `extra-large-increased` ≈ 32dp
- `extra-extra-large` ≈ 48dp

Use these for larger hero-surface components when you want more rounded appearance.

---

## Elevation

MD3 uses **tonal surface color** (not shadows) as the primary depth cue.
In dark mode, elevated surfaces get more primary color mixed in — this is automatic in M3.

| Level | Dp | Tonal Offset | Usage |
|---|---|---|---|
| 0 | 0dp | None | Flat surfaces, most components at rest |
| 1 | 1dp | +5% primary tint | Elevated cards, modal sheets |
| 2 | 3dp | +8% primary tint | Menus, nav bar, scrolled app bar |
| 3 | 6dp | +11% primary tint | FAB, dialogs, search |
| 4 | 8dp | +12% (hover/focus) | Hover/focus state increase |
| 5 | 12dp | +14% (hover/focus) | Hover/focus state increase |

```kotlin
// Card elevation
ElevatedCard(
    elevation = CardDefaults.elevatedCardElevation(defaultElevation = 6.dp)
) { }

// Custom surface with tonal elevation
Surface(tonalElevation = 3.dp) { }
```

---

## Motion

### M3 Easing Curves

```kotlin
// Define once in theme or use directly
val EmphasizedEasing       = CubicBezierEasing(0.2f, 0.0f, 0.0f, 1.0f)
val EmphasizedDecelerate   = CubicBezierEasing(0.05f, 0.7f, 0.1f, 1.0f)   // entering
val EmphasizedAccelerate   = CubicBezierEasing(0.3f, 0.0f, 0.8f, 0.15f)   // leaving
val StandardEasing         = CubicBezierEasing(0.2f, 0.0f, 0.0f, 1.0f)
val StandardDecelerate     = CubicBezierEasing(0.0f, 0.0f, 0.0f, 1.0f)
val StandardAccelerate     = CubicBezierEasing(0.3f, 0.0f, 1.0f, 1.0f)
```

### Standard Durations

| Category | Duration | Usage |
|---|---|---|
| Short 1 | 50ms | Micro color/opacity changes |
| Short 2 | 100ms | Icon state change |
| Short 3 | 150ms | Checkbox, radio, switch |
| Short 4 | 200ms | Chip expand/collapse |
| Medium 1 | 250ms | Dropdown, menu expand |
| Medium 2 | 300ms | FAB morph, card expand |
| Medium 3 | 350ms | Bottom sheet partial |
| Medium 4 | 400ms | Dialog appear |
| Long 1 | 450ms | Full bottom sheet |
| Long 2 | 500ms | Screen transitions |

### Spring Physics (M3 Expressive, 2025+)

MD3 Expressive introduced spring-based motion for interactive components. Use `spring()` for
things the user directly interacts with:

```kotlin
// Spring for interactive elements (feels physical)
val cardExpandSpec = spring<Float>(
    dampingRatio = Spring.DampingRatioMediumBouncy,
    stiffness    = Spring.StiffnessMedium
)

// Tween for transitions (predictable, declarative)
val screenTransitionSpec = tween<Float>(durationMillis = 400, easing = EmphasizedDecelerate)
```

### AnimatedVisibility

```kotlin
AnimatedVisibility(
    visible = isVisible,
    enter   = fadeIn(tween(300, easing = EmphasizedDecelerate)) +
              slideInVertically(tween(300, easing = EmphasizedDecelerate)) { it / 2 },
    exit    = fadeOut(tween(200, easing = EmphasizedAccelerate)) +
              slideOutVertically(tween(200, easing = EmphasizedAccelerate)) { it / 2 }
) {
    content()
}
```

### animate*AsState

```kotlin
// Color animation
val bgColor by animateColorAsState(
    targetValue   = if (selected) MaterialTheme.colorScheme.primaryContainer
                    else MaterialTheme.colorScheme.surface,
    animationSpec = tween(200, easing = EmphasizedEasing),
    label         = "backgroundColor"
)

// Size animation
val iconSize by animateDpAsState(
    targetValue   = if (expanded) 48.dp else 24.dp,
    animationSpec = spring(Spring.DampingRatioMediumBouncy),
    label         = "iconSize"
)
```

### animateContentSize

```kotlin
Card(
    modifier = Modifier
        .fillMaxWidth()
        .animateContentSize(
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness    = Spring.StiffnessMedium
            )
        )
        .clickable { expanded = !expanded }
) {
    Column(modifier = Modifier.padding(Dimens.md)) {
        Text("Title", style = MaterialTheme.typography.titleMedium)
        if (expanded) {
            Spacer(Modifier.height(Dimens.xs))
            Text("Expanded content...", style = MaterialTheme.typography.bodyMedium)
        }
    }
}
```

### Navigation Transitions

```kotlin
NavHost(
    navController    = navController,
    startDestination = HomeRoute,
    enterTransition  = {
        slideInHorizontally(tween(300, easing = EmphasizedDecelerate)) { it }
    },
    exitTransition = {
        slideOutHorizontally(tween(300, easing = EmphasizedAccelerate)) { -it / 3 }
    },
    popEnterTransition = {
        slideInHorizontally(tween(300, easing = EmphasizedDecelerate)) { -it / 3 }
    },
    popExitTransition = {
        slideOutHorizontally(tween(300, easing = EmphasizedAccelerate)) { it }
    }
) { /* composable routes */ }
```

---

## Motion Rules

- **Always** label `animate*AsState` and `rememberInfiniteTransition` with `label =` for tooling
- Use **spring** for interactive gestures; **tween** for programmatic transitions
- Entering elements: `EmphasizedDecelerate` (they decelerate into place)
- Leaving elements: `EmphasizedAccelerate` (they accelerate out quickly)
- Max duration: **500ms** screen-level, **300ms** component-level
- Test on real device — emulators hide performance issues
- Respect `Accessibility > Remove Animations` — check via `LocalInspectionMode` or user pref

---

## Official Docs

- [M3 Motion](https://m3.material.io/styles/motion/overview)
- [Compose Animation](https://developer.android.com/develop/ui/compose/animation/introduction)
- [M3 Type Scale](https://m3.material.io/styles/typography/type-scale-tokens)
- [Compose Typography](https://developer.android.com/develop/ui/compose/designsystems/material3#typography)
