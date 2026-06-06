# Storage — SQLDelight (KMP Database — Recommended)

> Read this file when the user selected **SQLDelight** for local database storage.
> SQLDelight is the **recommended database for KMP** — it generates type-safe Kotlin APIs
> from `.sq` SQL files and works on Android, Desktop (JVM), and iOS.

---

## When to use SQLDelight

| Scenario | Recommended |
|---|---|
| Offline-first app with synced data | ✅ SQLDelight |
| Complex queries, filtering, sorting | ✅ SQLDelight |
| Relationships between entities | ✅ SQLDelight |
| Shared database logic across platforms | ✅ SQLDelight (KMP-native) |
| Simple key-value prefs | ❌ Use DataStore/multiplatform-settings |

---

## Version Catalog Entries

> ⚠️ Fetch latest stable from: https://github.com/cashapp/sqldelight/releases

```toml
[versions]
sqldelight = "FETCH_FROM_OFFICIAL_SOURCE"   # https://github.com/cashapp/sqldelight/releases

[libraries]
# Runtime (commonMain)
sqldelight-runtime          = { module = "app.cash.sqldelight:runtime",                  version.ref = "sqldelight" }
# Coroutines extensions — Flow-based queries
sqldelight-coroutines       = { module = "app.cash.sqldelight:coroutines-extensions",   version.ref = "sqldelight" }

# Platform drivers — each goes in the right source set
sqldelight-driver-android   = { module = "app.cash.sqldelight:android-driver",           version.ref = "sqldelight" }
sqldelight-driver-jvm       = { module = "app.cash.sqldelight:sqlite-driver",            version.ref = "sqldelight" }  # Desktop
sqldelight-driver-ios       = { module = "app.cash.sqldelight:native-driver",            version.ref = "sqldelight" }  # iOS

[plugins]
sqldelight = { id = "app.cash.sqldelight", version.ref = "sqldelight" }
```

---

## Plugin Setup

### Root `build.gradle.kts`

```kotlin
plugins {
    alias(libs.plugins.sqldelight) apply false
}
```

### `shared/build.gradle.kts`

```kotlin
plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.sqldelight)            // ← add this
    // … other plugins
}

sqldelight {
    databases {
        create("AppDatabase") {
            packageName.set("<pkg>.database")
        }
    }
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation(libs.sqldelight.runtime)
            implementation(libs.sqldelight.coroutines)
        }
        androidMain.dependencies {
            implementation(libs.sqldelight.driver.android)
        }
        val jvmMain by getting {
            dependencies {
                implementation(libs.sqldelight.driver.jvm)
            }
        }
        iosMain.dependencies {
            implementation(libs.sqldelight.driver.ios)
        }
    }
}
```

---

## Schema — `.sq` Files

Place `.sq` files in `shared/src/commonMain/sqldelight/<pkg>/database/`.

```sql
-- shared/src/commonMain/sqldelight/<pkg>/database/Item.sq

CREATE TABLE Item (
    id          TEXT    NOT NULL PRIMARY KEY,
    title       TEXT    NOT NULL,
    description TEXT,
    is_done     INTEGER NOT NULL DEFAULT 0,   -- SQLite uses INTEGER for Boolean
    created_at  INTEGER NOT NULL              -- Unix timestamp (Long)
);

-- Queries become generated Kotlin functions:

getAllItems:
SELECT * FROM Item ORDER BY created_at DESC;

getItemById:
SELECT * FROM Item WHERE id = ?;

getItemsByDone:
SELECT * FROM Item WHERE is_done = ?;

insertItem:
INSERT INTO Item (id, title, description, is_done, created_at)
VALUES (?, ?, ?, ?, ?);

updateItem:
UPDATE Item SET title = ?, description = ?, is_done = ? WHERE id = ?;

deleteItem:
DELETE FROM Item WHERE id = ?;

deleteAllItems:
DELETE FROM Item;
```

SQLDelight generates a type-safe `AppDatabase` class and `ItemQueries` from this schema.

---

## Platform Driver — expect/actual

```kotlin
// commonMain/kotlin/<pkg>/database/DatabaseDriverFactory.kt
import app.cash.sqldelight.db.SqlDriver
expect class DatabaseDriverFactory {
    fun createDriver(): SqlDriver
}
```

```kotlin
// androidMain/kotlin/<pkg>/database/DatabaseDriverFactory.android.kt
import android.content.Context
import app.cash.sqldelight.driver.android.AndroidSqliteDriver
import app.cash.sqldelight.db.SqlDriver
import <pkg>.database.AppDatabase

actual class DatabaseDriverFactory(private val context: Context) {
    actual fun createDriver(): SqlDriver =
        AndroidSqliteDriver(AppDatabase.Schema, context, "app.db")
}
```

```kotlin
// jvmMain/kotlin/<pkg>/database/DatabaseDriverFactory.jvm.kt (Desktop)
import app.cash.sqldelight.driver.jdbc.sqlite.JdbcSqliteDriver
import app.cash.sqldelight.db.SqlDriver
import <pkg>.database.AppDatabase

actual class DatabaseDriverFactory {
    actual fun createDriver(): SqlDriver =
        JdbcSqliteDriver("jdbc:sqlite:app.db").also { AppDatabase.Schema.create(it) }
}
```

```kotlin
// iosMain/kotlin/<pkg>/database/DatabaseDriverFactory.ios.kt
import app.cash.sqldelight.driver.native.NativeSqliteDriver
import app.cash.sqldelight.db.SqlDriver
import <pkg>.database.AppDatabase

actual class DatabaseDriverFactory {
    actual fun createDriver(): SqlDriver =
        NativeSqliteDriver(AppDatabase.Schema, "app.db")
}
```

---

## Database Instance — commonMain

```kotlin
// commonMain/kotlin/<pkg>/database/Database.kt
import app.cash.sqldelight.db.SqlDriver
import <pkg>.database.AppDatabase

fun createDatabase(driver: SqlDriver): AppDatabase = AppDatabase(driver)
```

---

## Repository Pattern (commonMain)

```kotlin
// commonMain/kotlin/<pkg>/repository/ItemRepository.kt
package <pkg>.repository

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToList
import app.cash.sqldelight.coroutines.mapToOneOrNull
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import <pkg>.database.AppDatabase
import <pkg>.model.Item

class ItemRepository(private val db: AppDatabase) {

    private val queries = db.itemQueries

    // Reactive — emits whenever the table changes
    fun observeAllItems(): Flow<List<Item>> =
        queries.getAllItems()
            .asFlow()
            .mapToList(Dispatchers.Default)

    fun observeItemById(id: String): Flow<Item?> =
        queries.getItemById(id)
            .asFlow()
            .mapToOneOrNull(Dispatchers.Default)

    suspend fun insertItem(item: Item) = withContext(Dispatchers.Default) {
        queries.insertItem(
            id          = item.id,
            title       = item.title,
            description = item.description,
            is_done     = if (item.isDone) 1L else 0L,
            created_at  = item.createdAt
        )
    }

    suspend fun updateItem(item: Item) = withContext(Dispatchers.Default) {
        queries.updateItem(
            title       = item.title,
            description = item.description,
            is_done     = if (item.isDone) 1L else 0L,
            id          = item.id
        )
    }

    suspend fun deleteItem(id: String) = withContext(Dispatchers.Default) {
        queries.deleteItem(id)
    }

    suspend fun deleteAll() = withContext(Dispatchers.Default) {
        queries.deleteAllItems()
    }
}
```

---

## Domain Model Mapping

SQLDelight generates a data class per table row. Map it to your domain model:

```kotlin
// commonMain/kotlin/<pkg>/model/Item.kt
data class Item(
    val id: String,
    val title: String,
    val description: String?,
    val isDone: Boolean,
    val createdAt: Long
)

// Extension to map generated type → domain model
fun <pkg>.database.Item.toDomain() = Item(
    id          = id,
    title       = title,
    description = description,
    isDone      = is_done == 1L,
    createdAt   = created_at
)
```

---

## Database Migrations

```sql
-- shared/src/commonMain/sqldelight/<pkg>/database/migrations/1.sqm
ALTER TABLE Item ADD COLUMN priority INTEGER NOT NULL DEFAULT 0;
```

Update schema version in `build.gradle.kts`:

```kotlin
sqldelight {
    databases {
        create("AppDatabase") {
            packageName.set("<pkg>.database")
            version = 2       // increment for each migration
        }
    }
}
```

---

## Koin DI Wiring

```kotlin
// commonMain/kotlin/<pkg>/di/DatabaseModule.kt
import <pkg>.database.DatabaseDriverFactory
import <pkg>.database.createDatabase
import <pkg>.repository.ItemRepository
import org.koin.dsl.module

val databaseModule = module {
    single { DatabaseDriverFactory(get())  }   // 'get()' resolves Context on Android
    single { createDatabase(get<DatabaseDriverFactory>().createDriver()) }
    single { ItemRepository(get()) }
}
```

---

## MVI ViewModel Integration

```kotlin
// commonMain/kotlin/<pkg>/feature/items/ItemsViewModel.kt
class ItemsViewModel(
    private val repository: ItemRepository
) : BaseViewModel<ItemsUiState, ItemsUiEvent, ItemsUiEffect>() {

    override fun createInitialState() = ItemsUiState()

    init {
        // Observe DB reactively — UI auto-updates when data changes
        viewModelScope.launch {
            repository.observeAllItems().collect { items ->
                setState { copy(items = items, isLoading = false) }
            }
        }
    }

    override fun onEvent(event: ItemsUiEvent) {
        when (event) {
            is ItemsUiEvent.AddItem    -> addItem(event.title)
            is ItemsUiEvent.DeleteItem -> deleteItem(event.id)
            is ItemsUiEvent.ToggleDone -> toggleDone(event.item)
        }
    }

    private fun addItem(title: String) {
        viewModelScope.launch {
            repository.insertItem(Item(
                id        = uuid4().toString(),   // use uuid or similar
                title     = title,
                isDone    = false,
                createdAt = Clock.System.now().toEpochMilliseconds()
            ))
        }
    }

    private fun deleteItem(id: String) {
        viewModelScope.launch { repository.deleteItem(id) }
    }

    private fun toggleDone(item: Item) {
        viewModelScope.launch { repository.updateItem(item.copy(isDone = !item.isDone)) }
    }
}
```

---

## Official Docs

- [SQLDelight](https://cashapp.github.io/sqldelight/)
- [SQLDelight Releases](https://github.com/cashapp/sqldelight/releases)
- [Multiplatform Setup Guide](https://cashapp.github.io/sqldelight/multiplatform_sqlite/)
