# MVI Patterns Reference

## The Three Contracts

MVI (Model-View-Intent) defines a strict unidirectional data flow. Every feature has exactly three building blocks:

```
  UI  ──(Event)──▶  ViewModel  ──(State)──▶  UI
                         │
                      (Effect)
                         │
                    Side effects
               (navigation, dialogs, toasts)
```

| Contract | Type | Direction | Stored? |
|---|---|---|---|
| `UiState` | `data class` | ViewModel → UI | ✅ Yes — `StateFlow` |
| `UiEvent` | `sealed interface` | UI → ViewModel | ❌ No |
| `UiEffect` | `sealed interface` | ViewModel → UI (one-shot) | ❌ No — `SharedFlow` |

---

## UiState

- Must be an **immutable `data class`**
- All fields have default values (represents the initial empty state)
- Never contains logic — only pure data

```kotlin
data class FeatureUiState(
    val isLoading: Boolean           = false,
    val items: List<ItemModel>       = emptyList(),
    val selectedItem: ItemModel?     = null,
    val searchQuery: String          = "",
    val error: String?               = null
)
```

### Rules
- One `UiState` per screen / feature ViewModel
- Use `copy()` inside `setState {}` — never mutate fields directly
- Nested models should also be `data class` or `data object`
- `error: String?` (null = no error) is the standard error representation

---

## UiEvent

- Must be a **`sealed interface`** or `sealed class`
- One `sealed interface` per feature
- Leaf nodes are `data class` (with params) or `data object` (no params)

```kotlin
sealed interface FeatureUiEvent {
    // User triggered actions
    data class Search(val query: String)      : FeatureUiEvent
    data class SelectItem(val id: String)     : FeatureUiEvent
    data object RetryClicked                  : FeatureUiEvent
    data object DismissError                  : FeatureUiEvent

    // Lifecycle events
    data object ScreenOpened                  : FeatureUiEvent
    data object ScreenClosed                  : FeatureUiEvent
}
```

### Rules
- Every user action maps to one `UiEvent`
- UI only calls `onEvent(event)` — never accesses ViewModel internals directly
- Lifecycle events (`ScreenOpened`, `ScreenClosed`) trigger data loading / cleanup

---

## UiEffect

- Must be a **`sealed interface`**
- Represents **one-shot side effects** that should not persist in state
- Emitted via `SharedFlow` — consumed once by the UI

```kotlin
sealed interface FeatureUiEffect {
    data class NavigateTo(val route: String)      : FeatureUiEffect
    data object NavigateBack                       : FeatureUiEffect
    data class ShowSnackbar(val message: String)   : FeatureUiEffect
    data class ShowDialog(val dialogId: String)    : FeatureUiEffect
    data object RequestPermission                  : FeatureUiEffect
}
```

### Rules
- Never use `UiEffect` for things that belong in state (e.g., error messages should be in `UiState.error`)
- Navigation, toast/snackbar, and system dialog triggers → always `UiEffect`
- Collect effects in `LaunchedEffect(Unit)` — not `rememberCoroutineScope`

---

## BaseViewModel

```kotlin
// commonMain — zero Android dependencies
abstract class BaseViewModel<State : Any, Event : Any, Effect : Any> {

    abstract fun createInitialState(): State

    private val _state = MutableStateFlow(createInitialState())
    val state: StateFlow<State> = _state.asStateFlow()

    private val _effect = MutableSharedFlow<Effect>(extraBufferCapacity = 16)
    val effect: SharedFlow<Effect> = _effect.asSharedFlow()

    protected val viewModelScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    abstract fun onEvent(event: Event)

    protected fun setState(reduce: State.() -> State) {
        _state.update { it.reduce() }
    }

    protected fun sendEffect(builder: () -> Effect) {
        viewModelScope.launch { _effect.emit(builder()) }
    }

    open fun onCleared() {
        viewModelScope.cancel()
    }
}
```

---

## Concrete ViewModel Example

```kotlin
class ItemListViewModel(
    private val getItemsUseCase: GetItemsUseCase
) : BaseViewModel<ItemListUiState, ItemListUiEvent, ItemListUiEffect>() {

    override fun createInitialState() = ItemListUiState()

    override fun onEvent(event: ItemListUiEvent) {
        when (event) {
            is ItemListUiEvent.ScreenOpened   -> loadItems()
            is ItemListUiEvent.RetryClicked   -> loadItems()
            is ItemListUiEvent.DismissError   -> setState { copy(error = null) }
            is ItemListUiEvent.SelectItem     -> onItemSelected(event.id)
            is ItemListUiEvent.Search         -> onSearch(event.query)
        }
    }

    private fun loadItems() {
        viewModelScope.launch {
            setState { copy(isLoading = true, error = null) }
            getItemsUseCase()
                .onSuccess { items -> setState { copy(isLoading = false, items = items) } }
                .onFailure { e  -> setState { copy(isLoading = false, error = e.message) } }
        }
    }

    private fun onItemSelected(id: String) {
        sendEffect { ItemListUiEffect.NavigateTo("detail/$id") }
    }

    private fun onSearch(query: String) {
        setState { copy(searchQuery = query) }
        // debounce search with a coroutine delay if needed
    }
}
```

---

## Compose UI Wiring

```kotlin
@Composable
fun ItemListScreen(viewModel: ItemListViewModel) {
    val state by viewModel.state.collectAsState()

    // Collect one-shot effects — never inside onClick or event handlers
    LaunchedEffect(Unit) {
        viewModel.effect.collect { effect ->
            when (effect) {
                is ItemListUiEffect.NavigateTo    -> navController.navigate(effect.route)
                is ItemListUiEffect.ShowSnackbar  -> snackbarHostState.showSnackbar(effect.message)
                is ItemListUiEffect.NavigateBack  -> navController.popBackStack()
            }
        }
    }

    // Trigger screen-open event
    LaunchedEffect(Unit) {
        viewModel.onEvent(ItemListUiEvent.ScreenOpened)
    }

    // Render based on state
    when {
        state.isLoading  -> LoadingContent()
        state.error != null -> ErrorContent(
            message = state.error!!,
            onRetry = { viewModel.onEvent(ItemListUiEvent.RetryClicked) }
        )
        else -> ItemListContent(
            items    = state.items,
            onSelect = { id -> viewModel.onEvent(ItemListUiEvent.SelectItem(id)) }
        )
    }
}
```

---

## Use Case Pattern

Keep business logic in use cases — never in ViewModels directly.

```kotlin
// commonMain
class GetItemsUseCase(private val repository: ItemRepository) {
    suspend operator fun invoke(): Result<List<ItemModel>> =
        runCatching { repository.getItems() }
}
```

---

## File Naming Convention

```
feature/
├── ItemListScreen.kt          ← @Composable screen, subscribes to ViewModel
├── ItemListViewModel.kt       ← Extends BaseViewModel
├── ItemListContract.kt        ← UiState + UiEvent + UiEffect in one file
└── GetItemsUseCase.kt         ← Business logic
```

---

## Best Practices

### 1. Keep UiState flat and minimal

**❌ Anti-pattern — nested mutable state or too many flags:**
```kotlin
data class ItemListUiState(
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,     // isLoading already covers this
    val isEmptyStateVisible: Boolean = false,
    val isErrorVisible: Boolean = false,   // derive this from error != null
    val items: List<ItemModel> = emptyList()
)
```

**✅ Best practice — derive secondary state from primary data:**
```kotlin
data class ItemListUiState(
    val isLoading: Boolean = false,
    val items: List<ItemModel> = emptyList(),
    val error: String? = null
) {
    val isEmpty: Boolean get() = !isLoading && items.isEmpty() && error == null
    val hasError: Boolean get() = error != null
}
```

Computed properties in `UiState` remove the need to manually keep flags in sync.

---

### 2. One ViewModel per screen — never share across screens

**❌ Anti-pattern:**
```kotlin
// Injecting the same ViewModel into two screens
val sharedVm: ItemListViewModel = koinViewModel()
```

**✅ Best practice:** Each screen creates its own ViewModel. Pass data via navigation arguments
or a shared repository — never via a shared ViewModel instance.

---

### 3. Load data on ScreenOpened event, not in `init {}`

**❌ Anti-pattern — loading in init block:**
```kotlin
init {
    loadItems()   // Runs on every recomposition if ViewModel is recreated
}
```

**✅ Best practice — load from screen event:**
```kotlin
override fun onEvent(event: ItemListUiEvent) {
    when (event) {
        is ItemListUiEvent.ScreenOpened -> loadItems()   // Triggered once by LaunchedEffect(Unit)
    }
}
```
```kotlin
// In the Composable:
LaunchedEffect(Unit) {
    viewModel.onEvent(ItemListUiEvent.ScreenOpened)
}
```

This gives full control: you can replay, block, or debounce the load from the screen.

---

### 4. Navigate via UiEffect, never via NavController in ViewModel

**❌ Anti-pattern — NavController leaked into ViewModel:**
```kotlin
class MyViewModel(private val navController: NavController) : BaseViewModel<...>() {
    private fun onSuccess() {
        navController.navigate("detail/123")   // ViewModel must not hold UI references
    }
}
```

**✅ Best practice — navigate via Effect:**
```kotlin
// ViewModel
private fun onSuccess(id: String) {
    sendEffect { MyUiEffect.NavigateToDetail(id) }
}

// Composable
LaunchedEffect(Unit) {
    viewModel.effect.collect { effect ->
        when (effect) {
            is MyUiEffect.NavigateToDetail -> navController.navigate(DetailRoute(effect.id))
        }
    }
}
```

---

### 5. Use `Result<T>` for all repository operations

**❌ Anti-pattern — throwing exceptions from repositories:**
```kotlin
suspend fun getItems(): List<Item> {
    return api.fetchItems()   // Can throw — ViewModel must catch
}
```

**✅ Best practice — wrap with `runCatching`:**
```kotlin
// In repository or use case:
suspend fun getItems(): Result<List<Item>> = runCatching {
    api.fetchItems()
}

// In ViewModel:
getItemsUseCase()
    .onSuccess { items -> setState { copy(items = items, isLoading = false) } }
    .onFailure { e    -> setState { copy(error = e.message, isLoading = false) } }
```

---

### 6. Debounce search / rapid events in the ViewModel, not the UI

**❌ Anti-pattern — debouncing in Composable:**
```kotlin
// In Composable
LaunchedEffect(query) {
    delay(300)
    viewModel.onEvent(SearchEvent.Search(query))
}
```

**✅ Best practice — debounce in ViewModel:**
```kotlin
private var searchJob: Job? = null

private fun onSearch(query: String) {
    setState { copy(searchQuery = query) }
    searchJob?.cancel()
    searchJob = viewModelScope.launch {
        delay(300)
        performSearch(query)
    }
}
```

---

### 7. Separate UI concerns into sub-composables, not sub-ViewModels

Each screen has **one** ViewModel. Break the UI into `@Composable` functions that receive
state slices as parameters — not ViewModels:

```kotlin
// ✅ Good — composable receives data, not ViewModel
@Composable
fun ItemList(items: List<ItemModel>, onSelect: (String) -> Unit) { … }

// ❌ Bad — composable depends on ViewModel
@Composable
fun ItemList(viewModel: ItemListViewModel) { … }
```

---

### 8. Contract file structure — keep all three types together

```kotlin
// ItemListContract.kt — always keep State + Event + Effect in one file per feature
object ItemListContract {

    data class UiState(
        val isLoading: Boolean = false,
        val items: List<ItemModel> = emptyList(),
        val error: String? = null
    ) {
        val isEmpty get() = !isLoading && items.isEmpty() && error == null
    }

    sealed interface UiEvent {
        data object ScreenOpened              : UiEvent
        data class SelectItem(val id: String) : UiEvent
        data object RetryClicked              : UiEvent
        data class Search(val q: String)      : UiEvent
    }

    sealed interface UiEffect {
        data class NavigateTo(val route: Any)    : UiEffect
        data class ShowSnackbar(val msg: String) : UiEffect
        data object NavigateBack                  : UiEffect
    }
}
```

---

### 9. Always cancel ViewModel scope on `onCleared()`

The `BaseViewModel` already calls `viewModelScope.cancel()` in `onCleared()`. When integrating
with platform-specific ViewModels (e.g., `androidx.lifecycle.ViewModel` on Android), override
`onCleared()` and call `super.onCleared()`:

```kotlin
// androidMain — platform ViewModel wrapper
class AndroidItemListViewModel(
    private val baseVm: ItemListViewModel
) : androidx.lifecycle.ViewModel() {

    val state = baseVm.state
    val effect = baseVm.effect

    fun onEvent(event: ItemListContract.UiEvent) = baseVm.onEvent(event)

    override fun onCleared() {
        super.onCleared()
        baseVm.onCleared()   // Cancel commonMain coroutine scope
    }
}
```

---

### 10. Testing — ViewModel is plain Kotlin, test without Android dependencies

Because `BaseViewModel` lives in `commonMain` with no Android imports, all ViewModel tests
run as **pure JVM unit tests** — no Robolectric, no instrumentation:

```kotlin
// commonTest/kotlin/<pkg>/feature/ItemListViewModelTest.kt
class ItemListViewModelTest {

    private val fakeRepository = FakeItemRepository()
    private val viewModel = ItemListViewModel(GetItemsUseCase(fakeRepository))

    @Test
    fun `loading items emits loading then success state`() = runTest {
        val states = mutableListOf<ItemListContract.UiState>()
        val job = launch { viewModel.state.collect { states.add(it) } }

        viewModel.onEvent(ItemListContract.UiEvent.ScreenOpened)

        advanceUntilIdle()

        assertEquals(true, states[0].isLoading)
        assertEquals(false, states.last().isLoading)
        assertTrue(states.last().items.isNotEmpty())
        job.cancel()
    }

    @Test
    fun `error in repository emits error state`() = runTest {
        fakeRepository.shouldFail = true
        viewModel.onEvent(ItemListContract.UiEvent.ScreenOpened)
        advanceUntilIdle()
        assertNotNull(viewModel.state.value.error)
    }
}
```

---

## Feature Anatomy Checklist

When building a new feature, verify every item:

- [ ] `Contract.kt` — `UiState`, `UiEvent`, `UiEffect` defined in one file
- [ ] `UiState` is a `data class` with all-default constructor
- [ ] `UiEvent` is a `sealed interface`; leaf nodes are `data class`/`data object`
- [ ] `UiEffect` is a `sealed interface`; used only for one-shot side effects
- [ ] ViewModel extends `BaseViewModel` with the three contract generics
- [ ] `createInitialState()` returns a fully default `UiState`
- [ ] `onEvent()` delegates each event to a private function
- [ ] No `navController` reference inside ViewModel
- [ ] Data loading triggered by `ScreenOpened` event, not `init {}`
- [ ] Repository returns `Result<T>`, not raw type or exception
- [ ] Use cases are plain Kotlin classes in `commonMain`
- [ ] Screen collects `effect` in `LaunchedEffect(Unit)`
- [ ] Sub-composables receive state/lambdas — not the ViewModel
- [ ] ViewModel unit tests in `commonTest` with a fake repository
