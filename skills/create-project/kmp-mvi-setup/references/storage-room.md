# Storage — Room (Android / JVM Database)

> Read this file when the user selected **Room** for local database storage.
> Room is an Android-first ORM. It supports JVM (Desktop) via `room-runtime` but is
> **not supported on iOS**. For true KMP (Android + iOS + Desktop), prefer SQLDelight.

---

## When to use Room vs SQLDelight

| Factor | Room | SQLDelight |
|---|---|---|
| Targets | Android + JVM Desktop only | Android + iOS + Desktop ✅ |
| iOS support | ❌ No | ✅ Yes |
| Code generation | Annotation processing (KSP) | SQL-first (.sq files) |
| Query language | Annotated Kotlin DAOs | Plain SQL → type-safe Kotlin |
| KMP maturity | Limited KMP preview | Production KMP-native |
| **Use when** | Android-only or no iOS target | Full KMP project |

> ⚠️ **Room KMP is in developer preview.** For production KMP projects with iOS,
> use SQLDelight. For Android-only projects, Room is the established choice.

---

## Version Catalog Entries

> ⚠️ Fetch latest stable from: https://developer.android.com/jetpack/androidx/releases/room

```toml
[versions]
room = "FETCH_FROM_OFFICIAL_SOURCE"   # https://developer.android.com/jetpack/androidx/releases/room
ksp  = "FETCH_FROM_OFFICIAL_SOURCE"   # https://github.com/google/ksp/releases
                                       # Must match Kotlin version: e.g. Kotlin 2.1.21 → KSP 2.1.21-1.0.31

[libraries]
room-runtime  = { module = "androidx.room:room-runtime", version.ref = "room" }
room-ktx      = { module = "androidx.room:room-ktx",     version.ref = "room" }   # Coroutine extensions
room-compiler = { module = "androidx.room:room-compiler", version.ref = "room" }  # KSP annotation processor

[plugins]
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
```

> **KSP version rule**: KSP version must always have the same Kotlin prefix.
> e.g. Kotlin `2.1.21` → KSP `2.1.21-1.0.X` — check https://github.com/google/ksp/releases

---

## Plugin Setup

### Root `build.gradle.kts`

```kotlin
plugins {
    alias(libs.plugins.ksp) apply false
}
```

### `shared/build.gradle.kts` (Android + JVM only)

```kotlin
plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.ksp)               // ← add this
    // … other plugins
}

dependencies {
    // KSP runs per-target — specify each needed target
    add("kspAndroid", libs.room.compiler)
    add("kspJvm", libs.room.compiler)     // Desktop
}

kotlin {
    sourceSets {
        androidMain.dependencies {
            implementation(libs.room.runtime)
            implementation(libs.room.ktx)
        }
        val jvmMain by getting {
            dependencies {
                implementation(libs.room.runtime)
                implementation(libs.room.ktx)
            }
        }
    }
}
```

> ⚠️ Room entities and DAOs must be in `androidMain` or `jvmMain` (not `commonMain`)
> because Room KMP is not yet fully stable in shared code. Put shared business logic in
> `commonMain` and inject the DAO via a repository interface.

---

## Room Entity

```kotlin
// androidMain/kotlin/<pkg>/database/entity/ItemEntity.kt
package <pkg>.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "items")
data class ItemEntity(
    @PrimaryKey val id: String,
    val title: String,
    val description: String?,
    val isDone: Boolean,
    val createdAt: Long
)
```

---

## Room DAO

```kotlin
// androidMain/kotlin/<pkg>/database/dao/ItemDao.kt
package <pkg>.database.dao

import androidx.room.*
import kotlinx.coroutines.flow.Flow
import <pkg>.database.entity.ItemEntity

@Dao
interface ItemDao {
    @Query("SELECT * FROM items ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<ItemEntity>>

    @Query("SELECT * FROM items WHERE id = :id")
    fun observeById(id: String): Flow<ItemEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(item: ItemEntity)

    @Update
    suspend fun update(item: ItemEntity)

    @Query("DELETE FROM items WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM items")
    suspend fun deleteAll()
}
```

---

## Room Database

```kotlin
// androidMain/kotlin/<pkg>/database/AppDatabase.kt
package <pkg>.database

import androidx.room.Database
import androidx.room.RoomDatabase
import <pkg>.database.dao.ItemDao
import <pkg>.database.entity.ItemEntity

@Database(
    entities = [ItemEntity::class],
    version  = 1,
    exportSchema = true
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun itemDao(): ItemDao
}
```

---

## Database Instance (per platform)

```kotlin
// androidMain/kotlin/<pkg>/database/DatabaseFactory.android.kt
package <pkg>.database

import android.content.Context
import androidx.room.Room

fun createRoomDatabase(context: Context): AppDatabase =
    Room.databaseBuilder(
        context,
        AppDatabase::class.java,
        "app.db"
    ).build()
```

```kotlin
// jvmMain/kotlin/<pkg>/database/DatabaseFactory.jvm.kt (Desktop)
package <pkg>.database

import androidx.room.Room
import java.io.File

fun createRoomDatabase(): AppDatabase {
    val dbFile = File(System.getProperty("user.home"), ".app/app.db")
    return Room.databaseBuilder<AppDatabase>(
        name = dbFile.absolutePath
    ).build()
}
```

---

## Repository via Interface (commonMain)

Use an interface in `commonMain` so the ViewModel is platform-agnostic:

```kotlin
// commonMain/kotlin/<pkg>/repository/ItemRepository.kt
import kotlinx.coroutines.flow.Flow
import <pkg>.model.Item

interface ItemRepository {
    fun observeAll(): Flow<List<Item>>
    suspend fun insert(item: Item)
    suspend fun update(item: Item)
    suspend fun delete(id: String)
}
```

```kotlin
// androidMain/kotlin/<pkg>/repository/RoomItemRepository.kt
class RoomItemRepository(private val dao: ItemDao) : ItemRepository {
    override fun observeAll(): Flow<List<Item>> =
        dao.observeAll().map { list -> list.map { it.toDomain() } }

    override suspend fun insert(item: Item) = dao.insert(item.toEntity())
    override suspend fun update(item: Item) = dao.update(item.toEntity())
    override suspend fun delete(id: String) = dao.deleteById(id)
}
```

---

## Koin DI Wiring

```kotlin
// androidMain/kotlin/<pkg>/di/DatabaseModule.android.kt
import <pkg>.database.createRoomDatabase
import <pkg>.database.dao.ItemDao
import <pkg>.repository.ItemRepository
import <pkg>.repository.RoomItemRepository
import org.koin.dsl.module

val databaseModule = module {
    single { createRoomDatabase(get()) }         // 'get()' resolves Android Context
    single<ItemDao> { get<AppDatabase>().itemDao() }
    single<ItemRepository> { RoomItemRepository(get()) }
}
```

---

## Migrations

```kotlin
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE items ADD COLUMN priority INTEGER NOT NULL DEFAULT 0")
    }
}

// In database builder:
Room.databaseBuilder(context, AppDatabase::class.java, "app.db")
    .addMigrations(MIGRATION_1_2)
    .build()
```

---

## Official Docs

- [Room Overview](https://developer.android.com/training/data-storage/room)
- [Room KMP (preview)](https://developer.android.com/kotlin/multiplatform/room)
- [Room Releases](https://developer.android.com/jetpack/androidx/releases/room)
- [KSP Releases](https://github.com/google/ksp/releases)
