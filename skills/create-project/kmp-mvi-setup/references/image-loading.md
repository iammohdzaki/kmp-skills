# Image Loading Reference

## Options at a Glance

| Library | KMP Support | API Style | Recommended For |
|---|---|---|---|
| **Coil 3 + Landscapist** | ✅ Android + Desktop | Composable wrappers | Most apps — simplest API |
| **Coil 3 standalone** | ✅ Android + Desktop | `AsyncImage`, `ImageRequest` | When you want Coil's full API control |
| **Glide** | ❌ Android only | `GlideImage` Composable | Android-only projects |

---

## Option 1: Coil 3 + Landscapist (Recommended for KMP)

Landscapist wraps Coil with ergonomic composables: loading/error/placeholder slots built-in.

### Versions

```toml
# gradle/libs.versions.toml
[versions]
coil         = "3.1.0"
landscapist  = "2.4.7"

[libraries]
coil-compose      = { module = "io.coil-kt.coil3:coil-compose",       version.ref = "coil" }
coil-network-ktor = { module = "io.coil-kt.coil3:coil-network-ktor",  version.ref = "coil" }
landscapist-coil  = { module = "com.github.skydoves:landscapist-coil3", version.ref = "landscapist" }
landscapist-placeholder = { module = "com.github.skydoves:landscapist-placeholder", version.ref = "landscapist" }
landscapist-animation   = { module = "com.github.skydoves:landscapist-animation",   version.ref = "landscapist" }
```

### Gradle Dependencies

```kotlin
// composeApp/build.gradle.kts
sourceSets {
    commonMain.dependencies {
        implementation(libs.coil.compose)
        implementation(libs.coil.network.ktor)
        implementation(libs.landscapist.coil)
        implementation(libs.landscapist.placeholder)
        implementation(libs.landscapist.animation)  // optional: crossfade
    }
}
```

### Basic Usage

```kotlin
import com.skydoves.landscapist.coil3.CoilImage
import com.skydoves.landscapist.ImageOptions
import com.skydoves.landscapist.animation.crossfade.CrossfadePlugin
import com.skydoves.landscapist.placeholder.shimmer.ShimmerPlugin

@Composable
fun NetworkImage(
    url: String,
    modifier: Modifier = Modifier,
    contentDescription: String? = null,
    contentScale: ContentScale = ContentScale.Crop
) {
    CoilImage(
        imageModel          = { url },
        imageOptions        = ImageOptions(
            contentScale    = contentScale,
            contentDescription = contentDescription
        ),
        modifier            = modifier,
        component           = rememberImageComponent {
            // Shimmer placeholder while loading
            +ShimmerPlugin(
                baseColor     = MaterialTheme.colorScheme.surfaceVariant,
                highlightColor = MaterialTheme.colorScheme.surface
            )
            // Crossfade when image loads
            +CrossfadePlugin(duration = 300)
        },
        failure = {
            // Error state
            Box(
                modifier = modifier.background(MaterialTheme.colorScheme.errorContainer),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector        = Icons.Default.BrokenImage,
                    contentDescription = "Failed to load image",
                    tint               = MaterialTheme.colorScheme.onErrorContainer
                )
            }
        }
    )
}
```

### Usage in Screens

```kotlin
NetworkImage(
    url               = item.imageUrl,
    contentDescription = item.title,
    modifier          = Modifier
        .fillMaxWidth()
        .height(200.dp)
        .clip(MaterialTheme.shapes.medium)
)
```

---

## Option 2: Coil 3 Standalone

When you prefer Coil's native `AsyncImage` composable without Landscapist.

### Versions

```toml
[versions]
coil = "3.1.0"

[libraries]
coil-compose      = { module = "io.coil-kt.coil3:coil-compose",      version.ref = "coil" }
coil-network-ktor = { module = "io.coil-kt.coil3:coil-network-ktor", version.ref = "coil" }
```

### Basic Usage

```kotlin
import coil3.compose.AsyncImage
import coil3.compose.LocalPlatformContext
import coil3.request.ImageRequest
import coil3.request.crossfade

@Composable
fun NetworkImage(
    url: String,
    modifier: Modifier = Modifier,
    contentDescription: String? = null,
    contentScale: ContentScale = ContentScale.Crop
) {
    val context = LocalPlatformContext.current

    AsyncImage(
        model = ImageRequest.Builder(context)
            .data(url)
            .crossfade(true)
            .build(),
        contentDescription = contentDescription,
        contentScale       = contentScale,
        modifier           = modifier,
        placeholder        = painterResource(Res.drawable.placeholder),
        error              = painterResource(Res.drawable.error_image)
    )
}
```

---

## Coil SingletonImageLoader (Optional Global Config)

For network headers, caching policy, or logging — configure once at app startup:

```kotlin
// commonMain or androidMain
SingletonImageLoader.setSafe { context ->
    ImageLoader.Builder(context)
        .components {
            add(KtorNetworkFetcherFactory())
        }
        .diskCachePolicy(CachePolicy.ENABLED)
        .memoryCachePolicy(CachePolicy.ENABLED)
        .build()
}
```

---

## Option 3: Glide (Android only)

Only use this if your project targets **Android only** (not KMP).

```toml
[versions]
glide = "1.0.0-beta01"

[libraries]
glide-compose = { module = "com.github.bumptech.glide:compose", version.ref = "glide" }
```

```kotlin
import com.bumptech.glide.integration.compose.ExperimentalGlideComposeApi
import com.bumptech.glide.integration.compose.GlideImage

@OptIn(ExperimentalGlideComposeApi::class)
@Composable
fun NetworkImage(url: String, modifier: Modifier = Modifier) {
    GlideImage(
        model              = url,
        contentDescription = null,
        modifier           = modifier,
        contentScale       = ContentScale.Crop
    )
}
```

---

## Rules

- Wrap image loading in a reusable `NetworkImage` composable — never call library APIs directly in screens
- Always provide a loading placeholder and an error state
- Use `contentScale = ContentScale.Crop` for thumbnails, `ContentScale.Fit` for full images
- Always pass a meaningful `contentDescription` — null only for purely decorative images
- For KMP (Android + Desktop), Coil 3 with Ktor network fetcher is the safest choice

---

## Official Docs

- [Coil 3](https://coil-kt.github.io/coil/)
- [Coil KMP guide](https://coil-kt.github.io/coil/getting_started/#multiplatform)
- [Landscapist](https://github.com/skydoves/landscapist)
- [Glide Compose](https://bumptech.github.io/glide/int/compose.html)
