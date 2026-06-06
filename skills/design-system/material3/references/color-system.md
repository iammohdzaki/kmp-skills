# MD3 Color System — Compose / KMP

Complete reference for Material Design 3's color system in **Jetpack Compose** and
**Compose Multiplatform**. Covers color roles, tonal palettes, dynamic color, and scheme setup.

---

## Color Roles Overview

MD3 defines 29 color roles. In Compose they are accessed via `MaterialTheme.colorScheme`.
**Never** use raw `Color(0xFF...)` values in composables — always reference a semantic role.

---

## Accent Colors

Three accent groups (primary, secondary, tertiary) each with 4 roles:

| Role | Compose Token | Purpose |
|---|---|---|
| Primary | `colorScheme.primary` | High-emphasis fills, key actions (FAB, active states) |
| On Primary | `colorScheme.onPrimary` | Text and icons on primary |
| Primary Container | `colorScheme.primaryContainer` | Standout fill (tonal buttons, selected chips) |
| On Primary Container | `colorScheme.onPrimaryContainer` | Text and icons on primary container |
| Secondary | `colorScheme.secondary` | Less prominent fills and accents |
| On Secondary | `colorScheme.onSecondary` | Text and icons on secondary |
| Secondary Container | `colorScheme.secondaryContainer` | Recessive components (tonal buttons) |
| On Secondary Container | `colorScheme.onSecondaryContainer` | Text and icons on secondary container |
| Tertiary | `colorScheme.tertiary` | Complementary fills for contrast |
| On Tertiary | `colorScheme.onTertiary` | Text and icons on tertiary |
| Tertiary Container | `colorScheme.tertiaryContainer` | Complementary container fill |
| On Tertiary Container | `colorScheme.onTertiaryContainer` | Text and icons on tertiary container |

**Usage guidance:**
- **Primary**: FABs, high-emphasis buttons, active nav items, toggle on-states
- **Secondary**: Filter chips, tonal buttons, secondary selected states
- **Tertiary**: Contrasting accents that balance primary/secondary — badges, input highlights

---

## Error Colors

Static — do not change with dynamic color:

| Role | Compose Token | Purpose |
|---|---|---|
| Error | `colorScheme.error` | Error state fills, attention-grabbing indicators |
| On Error | `colorScheme.onError` | Text and icons on error |
| Error Container | `colorScheme.errorContainer` | Error banner or snackbar background |
| On Error Container | `colorScheme.onErrorContainer` | Text and icons on error container |

---

## Surface Colors

| Role | Compose Token | Purpose |
|---|---|---|
| Surface | `colorScheme.surface` | Default background for cards, sheets, menus |
| On Surface | `colorScheme.onSurface` | Text and icons on any surface |
| On Surface Variant | `colorScheme.onSurfaceVariant` | Lower-emphasis text/icons (placeholders, hints) |
| Surface Container Lowest | `colorScheme.surfaceContainerLowest` | Lowest-emphasis container |
| Surface Container Low | `colorScheme.surfaceContainerLow` | Low-emphasis container |
| Surface Container | `colorScheme.surfaceContainer` | Default container (navigation areas) |
| Surface Container High | `colorScheme.surfaceContainerHigh` | High-emphasis container (dialogs) |
| Surface Container Highest | `colorScheme.surfaceContainerHighest` | Highest-emphasis container |
| Surface Dim | `colorScheme.surfaceDim` | Dimmest surface in both themes |
| Surface Bright | `colorScheme.surfaceBright` | Brightest surface in both themes |
| Background | `colorScheme.background` | Screen/page background |
| On Background | `colorScheme.onBackground` | Text and icons on background |

**Surface container hierarchy**: `surfaceContainerLowest` → `surfaceContainer` → `surfaceContainerHighest`
creates visual nesting depth without shadows. Use for multi-pane layouts.

---

## Inverse Colors

For elements that must contrast against the surrounding UI (e.g., snackbars):

| Role | Compose Token | Purpose |
|---|---|---|
| Inverse Surface | `colorScheme.inverseSurface` | Background for contrasting elements |
| Inverse On Surface | `colorScheme.inverseOnSurface` | Text on inverse surface |
| Inverse Primary | `colorScheme.inversePrimary` | Actionable text on inverse surface |

---

## Outline Colors

| Role | Compose Token | Purpose |
|---|---|---|
| Outline | `colorScheme.outline` | Important boundaries (text field borders, focus rings) |
| Outline Variant | `colorScheme.outlineVariant` | Decorative dividers, subtle borders |

---

## Defining Custom Color Schemes

Generate your palette at **https://material-foundation.github.io/material-theme-builder/** — it exports exact Compose `ColorScheme` code.

```kotlin
// theme/Color.kt

private val LightColorScheme = lightColorScheme(
    primary                  = Color(0xFF6750A4),
    onPrimary                = Color(0xFFFFFFFF),
    primaryContainer         = Color(0xFFEADDFF),
    onPrimaryContainer       = Color(0xFF21005D),
    secondary                = Color(0xFF625B71),
    onSecondary              = Color(0xFFFFFFFF),
    secondaryContainer       = Color(0xFFE8DEF8),
    onSecondaryContainer     = Color(0xFF1D192B),
    tertiary                 = Color(0xFF7D5260),
    onTertiary               = Color(0xFFFFFFFF),
    tertiaryContainer        = Color(0xFFFFD8E4),
    onTertiaryContainer      = Color(0xFF31111D),
    error                    = Color(0xFFB3261E),
    onError                  = Color(0xFFFFFFFF),
    errorContainer           = Color(0xFFF9DEDC),
    onErrorContainer         = Color(0xFF410E0B),
    background               = Color(0xFFFFFBFE),
    onBackground             = Color(0xFF1C1B1F),
    surface                  = Color(0xFFFFFBFE),
    onSurface                = Color(0xFF1C1B1F),
    surfaceVariant           = Color(0xFFE7E0EC),
    onSurfaceVariant         = Color(0xFF49454F),
    outline                  = Color(0xFF79747E),
    outlineVariant           = Color(0xFFCAC4D0),
    scrim                    = Color(0xFF000000),
    inverseSurface           = Color(0xFF313033),
    inverseOnSurface         = Color(0xFFF4EFF4),
    inversePrimary           = Color(0xFFD0BCFF),
)

private val DarkColorScheme = darkColorScheme(
    primary                  = Color(0xFFD0BCFF),
    onPrimary                = Color(0xFF381E72),
    primaryContainer         = Color(0xFF4F378B),
    onPrimaryContainer       = Color(0xFFEADDFF),
    secondary                = Color(0xFFCCC2DC),
    onSecondary              = Color(0xFF332D41),
    secondaryContainer       = Color(0xFF4A4458),
    onSecondaryContainer     = Color(0xFFE8DEF8),
    tertiary                 = Color(0xFFEFB8C8),
    onTertiary               = Color(0xFF492532),
    tertiaryContainer        = Color(0xFF633B48),
    onTertiaryContainer      = Color(0xFFFFD8E4),
    error                    = Color(0xFFF2B8B5),
    onError                  = Color(0xFF601410),
    errorContainer           = Color(0xFF8C1D18),
    onErrorContainer         = Color(0xFFF9DEDC),
    background               = Color(0xFF1C1B1F),
    onBackground             = Color(0xFFE6E1E5),
    surface                  = Color(0xFF1C1B1F),
    onSurface                = Color(0xFFE6E1E5),
    surfaceVariant           = Color(0xFF49454F),
    onSurfaceVariant         = Color(0xFFCAC4D0),
    outline                  = Color(0xFF938F99),
    outlineVariant           = Color(0xFF49454F),
    scrim                    = Color(0xFF000000),
    inverseSurface           = Color(0xFFE6E1E5),
    inverseOnSurface         = Color(0xFF313033),
    inversePrimary           = Color(0xFF6750A4),
)
```

---

## Dynamic Color (Android 12+ only)

Dynamic color generates the full `ColorScheme` from the user's wallpaper.
**Always provide a static fallback** for older Android and Desktop targets.

```kotlin
// androidMain — use LocalContext for dynamic color
@Composable
fun platformColorScheme(darkTheme: Boolean, dynamicColor: Boolean): ColorScheme {
    return when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else      -> LightColorScheme
    }
}

// jvmMain (Desktop) — no dynamic color API
@Composable
fun platformColorScheme(darkTheme: Boolean, dynamicColor: Boolean): ColorScheme {
    return if (darkTheme) DarkColorScheme else LightColorScheme
}
```

---

## Custom Color Extension (Beyond M3 Roles)

For brand-specific colors not covered by M3 (e.g., success, warning):

```kotlin
// theme/ExtendedColors.kt
data class ExtendedColors(
    val success: Color,
    val onSuccess: Color,
    val successContainer: Color,
    val onSuccessContainer: Color,
    val warning: Color,
    val onWarning: Color,
    val warningContainer: Color,
    val onWarningContainer: Color,
)

val LocalExtendedColors = staticCompositionLocalOf {
    ExtendedColors(
        success            = Color(0xFF386A20),
        onSuccess          = Color(0xFFFFFFFF),
        successContainer   = Color(0xFFB7F397),
        onSuccessContainer = Color(0xFF072100),
        warning            = Color(0xFF7A5900),
        onWarning          = Color(0xFFFFFFFF),
        warningContainer   = Color(0xFFFFDFA0),
        onWarningContainer = Color(0xFF261A00),
    )
}

// Provide in AppTheme
CompositionLocalProvider(LocalExtendedColors provides lightExtendedColors) {
    MaterialTheme(...) { content() }
}

// Access in composables
val colors = LocalExtendedColors.current
Box(modifier = Modifier.background(colors.successContainer)) { ... }
```

---

## Accessibility: Contrast Requirements

| Context | Minimum Ratio |
|---|---|
| Normal text (< 18sp, non-bold) | **4.5 : 1** |
| Large text (≥ 18sp or ≥ 14sp bold) | **3 : 1** |
| UI components and icons | **3 : 1** |
| Decorative elements | None |

M3 baseline color schemes are WCAG AA compliant.
Validate custom palettes at https://webaim.org/resources/contrastchecker/

---

## Rules

- **Never** use `Color(0xFF...)` directly in composables — always `MaterialTheme.colorScheme.*`
- **Never** swap semantic roles (e.g., don't use `error` for success states)
- Always define both `LightColorScheme` and `DarkColorScheme`
- For KMP Desktop: always use static schemes — no `dynamicDarkColorScheme` on JVM
- Generate palettes from the [M3 Theme Builder](https://material-foundation.github.io/material-theme-builder/)
- Test every surface in both dark and light mode before shipping

---

## Tools

- [M3 Theme Builder](https://material-foundation.github.io/material-theme-builder/)
- [Material Color Utilities (Kotlin)](https://github.com/material-foundation/material-color-utilities)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
