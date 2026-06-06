# MD3 Theming and Dynamic Color — Compose / KMP

Complete guide to setting up Material Design 3 themes in **Jetpack Compose** and
**Compose Multiplatform** (Android + Desktop).

---

## Theme Architecture

The same semantic roles (primary, onSurface, surface containers, etc.) appear on both platforms.
The difference is that **dynamic color** is only available on Android 12+.

| Platform | Theme approach |
|---|---|
| **Android (API 31+)** | `dynamicDarkColorScheme` / `dynamicLightColorScheme` + static fallback |
| **Android (API < 31)** | Static `lightColorScheme` / `darkColorScheme` |
| **Desktop (JVM)** | Static `lightColorScheme` / `darkColorScheme` always |

---

## AppTheme Setup

### expect/actual pattern for KMP

Split dynamic color logic across platforms using `expect`/`actual` or an interface:

```kotlin
// commonMain — AppTheme.kt
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = rememberColorScheme(darkTheme = darkTheme, dynamicColor = dynamicColor)

    MaterialTheme(
        colorScheme = colorScheme,
        typography  = AppTypography,
        shapes      = AppShapes,
        content     = content
    )
}

// commonMain — expect declaration
@Composable
expect fun rememberColorScheme(darkTheme: Boolean, dynamicColor: Boolean): ColorScheme
```

```kotlin
// androidMain — actual implementation
@Composable
actual fun rememberColorScheme(darkTheme: Boolean, dynamicColor: Boolean): ColorScheme {
    return when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else      -> LightColorScheme
    }
}

// jvmMain — actual implementation (Desktop — no dynamic color)
@Composable
actual fun rememberColorScheme(darkTheme: Boolean, dynamicColor: Boolean): ColorScheme {
    return if (darkTheme) DarkColorScheme else LightColorScheme
}
```

### Simplified single-target (Android only)

```kotlin
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
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

---

## Static Color Schemes

Define in `theme/Color.kt`. Generate from [M3 Theme Builder](https://material-foundation.github.io/material-theme-builder/).

```kotlin
internal val LightColorScheme = lightColorScheme(
    primary          = Color(0xFF6750A4),
    onPrimary        = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFEADDFF),
    // ... remaining roles from Color.md
)

internal val DarkColorScheme = darkColorScheme(
    primary          = Color(0xFFD0BCFF),
    onPrimary        = Color(0xFF381E72),
    primaryContainer = Color(0xFF4F378B),
    // ... remaining roles from Color.md
)
```

---

## Typography Setup

```kotlin
// theme/AppTypography.kt
val AppTypography = Typography(
    displayLarge = TextStyle(
        fontFamily    = AppFontFamily,
        fontWeight    = FontWeight.Light,
        fontSize      = 57.sp,
        lineHeight    = 64.sp,
        letterSpacing = (-0.25).sp
    ),
    bodyLarge = TextStyle(
        fontFamily    = AppFontFamily,
        fontWeight    = FontWeight.Normal,
        fontSize      = 16.sp,
        lineHeight    = 24.sp,
        letterSpacing = 0.5.sp
    ),
    labelLarge = TextStyle(
        fontFamily    = AppFontFamily,
        fontWeight    = FontWeight.Medium,
        fontSize      = 14.sp,
        lineHeight    = 20.sp,
        letterSpacing = 0.1.sp
    ),
    // Define all 15 styles — see references/typography-and-shape.md
)
```

---

## Shape Setup

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

---

## Spacing Token Setup

MD3 uses an 8dp spacing system. Define once, reference everywhere:

```kotlin
// theme/Dimens.kt
object Dimens {
    // 4dp grid
    val xxs  = 4.dp    // icon padding, tight gaps
    val xs   = 8.dp    // between related elements
    val sm   = 12.dp   // small internal padding
    val md   = 16.dp   // standard screen padding, card internal
    val lg   = 24.dp   // section gaps
    val xl   = 32.dp   // major section separators
    val xxl  = 48.dp   // hero spacing

    // Standard screen margins
    val screenHorizontal = 16.dp
    val screenVertical   = 16.dp
}
```

---

## Full Theme File Structure

```
theme/
├── AppTheme.kt       ← MaterialTheme composition, dark mode, dynamic color
├── Color.kt          ← LightColorScheme + DarkColorScheme
├── AppTypography.kt  ← Typography (all 15 styles)
├── AppShapes.kt      ← Shapes (extraSmall → extraLarge)
├── Dimens.kt         ← Spacing tokens
└── ExtendedColors.kt ← Custom colors beyond M3 roles (optional)
```

---

## Applying the Theme

```kotlin
// androidMain — MainActivity
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()  // draw behind system bars
        setContent {
            AppTheme {
                // Root composable
                App()
            }
        }
    }
}

// jvmMain — main.kt (Desktop)
fun main() = application {
    Window(onCloseRequest = ::exitApplication, title = "App Name") {
        AppTheme(darkTheme = false) {
            App()
        }
    }
}
```

---

## Edge-to-Edge (Android)

Use `enableEdgeToEdge()` and `WindowInsets` modifiers so content draws behind system bars correctly:

```kotlin
// In Activity
enableEdgeToEdge()

// In Compose — Scaffold handles insets automatically
Scaffold(
    modifier = Modifier.fillMaxSize(),
    topBar   = { TopAppBar(title = { Text("Home") }) },
    content  = { paddingValues ->
        // paddingValues already includes status bar + nav bar padding
        LazyColumn(contentPadding = paddingValues) { }
    }
)

// For non-Scaffold screens
Box(
    modifier = Modifier
        .fillMaxSize()
        .statusBarsPadding()
        .navigationBarsPadding()
) { }
```

---

## Dark Mode Toggle (User Preference)

```kotlin
// Store in DataStore or remember state
var darkTheme by rememberSaveable { mutableStateOf(false) }
var useSystemTheme by rememberSaveable { mutableStateOf(true) }

AppTheme(
    darkTheme = if (useSystemTheme) isSystemInDarkTheme() else darkTheme
) {
    App()
}
```

---

## Theming Previews

```kotlin
@Preview(name = "Light")
@Preview(name = "Dark", uiMode = UI_MODE_NIGHT_YES)
@Composable
fun MyScreenPreview() {
    AppTheme {
        MyScreen()
    }
}
```

---

## Rules

- `AppTheme` is the **only** place `MaterialTheme` is called — never wrap individual screens
- Always call `enableEdgeToEdge()` on Android before `setContent {}`
- Dynamic color should be **opt-in** via a parameter — not forced on all users
- Desktop never has dynamic color — always use the static scheme
- Define all spacing in `Dimens` — never scatter raw `Dp` literals in reusable UI

---

## Official Docs

- [Compose Material 3 Theming](https://developer.android.com/develop/ui/compose/designsystems/material3)
- [M3 Theme Builder](https://material-foundation.github.io/material-theme-builder/)
- [Dynamic Color](https://developer.android.com/develop/ui/views/theming/dynamic-colors)
- [Edge-to-Edge](https://developer.android.com/develop/ui/compose/layouts/insets)
