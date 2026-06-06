# MD3 Component Catalog — Compose / KMP

Complete reference for Material Design 3 components in **Jetpack Compose** and
**Compose Multiplatform**. All examples use `androidx.compose.material3`.

> **I/O 2026 note**: Lists, menus, search, and search app bars have refreshed expressive guidance.
> Check your `androidx.compose.material3` BOM version for expressive variants.

---

## Actions

### Buttons

MD3 has 5 button types ordered by emphasis: Filled > Filled Tonal > Elevated > Outlined > Text.
Use only **one Filled button** per section. Prefer lower-emphasis variants for secondary actions.

```kotlin
// 1. Filled — highest emphasis, primary action
Button(onClick = onConfirm) { Text("Confirm") }

// 2. Filled Tonal — secondary primary action
FilledTonalButton(onClick = onSaveDraft) { Text("Save Draft") }

// 3. Elevated — medium emphasis with shadow (use sparingly)
ElevatedButton(onClick = onAddToCart) { Text("Add to Cart") }

// 4. Outlined — medium emphasis, neutral secondary
OutlinedButton(onClick = onCancel) { Text("Cancel") }

// 5. Text — lowest emphasis, inline or tertiary actions
TextButton(onClick = onLearnMore) { Text("Learn more") }

// Disabled state
Button(onClick = {}, enabled = isFormValid) { Text("Submit") }

// Button with leading icon
Button(onClick = onSend) {
    Icon(
        imageVector = Icons.Default.Send,
        contentDescription = null,
        modifier = Modifier.size(ButtonDefaults.IconSize)
    )
    Spacer(Modifier.size(ButtonDefaults.IconSpacing))
    Text("Send")
}

// Button sizes (Expressive, M3 2025+) — via Modifier.height
Button(onClick = {}, modifier = Modifier.height(32.dp)) { Text("XS") }  // extra-small
Button(onClick = {}, modifier = Modifier.height(40.dp)) { Text("S") }   // small (default)
Button(onClick = {}, modifier = Modifier.height(48.dp)) { Text("M") }   // medium
Button(onClick = {}, modifier = Modifier.height(56.dp)) { Text("L") }   // large
Button(onClick = {}, modifier = Modifier.height(64.dp)) { Text("XL") }  // extra-large
```

**A11y**: Minimum touch target 48×48dp. `contentDescription` on icon-only buttons.

---

### FAB (Floating Action Button)

```kotlin
// Standard FAB — one primary action per screen
FloatingActionButton(
    onClick        = onCreate,
    containerColor = MaterialTheme.colorScheme.primaryContainer
) {
    Icon(Icons.Default.Add, contentDescription = "Create")
}

// Small FAB — limited space
SmallFloatingActionButton(onClick = onCreate) {
    Icon(Icons.Default.Add, contentDescription = "Create")
}

// Large FAB — prominent hero action
LargeFloatingActionButton(onClick = onCreate) {
    Icon(Icons.Default.Add, contentDescription = "Create", modifier = Modifier.size(36.dp))
}

// Extended FAB — with label
ExtendedFloatingActionButton(
    text    = { Text("New Item") },
    icon    = { Icon(Icons.Default.Add, contentDescription = null) },
    onClick = onCreate
)

// Extended FAB — collapse on scroll
val listState = rememberLazyListState()
val isExpanded by remember { derivedStateOf { listState.firstVisibleItemIndex == 0 } }

ExtendedFloatingActionButton(
    text     = { Text("Compose") },
    icon     = { Icon(Icons.Default.Edit, contentDescription = null) },
    expanded = isExpanded,
    onClick  = onCompose
)
```

**Rule**: FAB goes in `Scaffold.floatingActionButton` — never position it manually.

---

### Icon Buttons

```kotlin
// Standard icon button
IconButton(onClick = onSettings) {
    Icon(Icons.Default.Settings, contentDescription = "Settings")
}

// Filled icon button — high emphasis
FilledIconButton(onClick = onSend) {
    Icon(Icons.Default.Send, contentDescription = "Send")
}

// Filled tonal icon button
FilledTonalIconButton(onClick = onLike) {
    Icon(Icons.Default.FavoriteBorder, contentDescription = "Like")
}

// Outlined icon button
OutlinedIconButton(onClick = onShare) {
    Icon(Icons.Default.Share, contentDescription = "Share")
}

// Toggle icon button
var liked by remember { mutableStateOf(false) }
IconToggleButton(checked = liked, onCheckedChange = { liked = it }) {
    Icon(
        imageVector = if (liked) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
        contentDescription = if (liked) "Unlike" else "Like"
    )
}
```

---

### Segmented Buttons

```kotlin
val options  = listOf("Day", "Week", "Month")
var selected by remember { mutableIntStateOf(0) }

SingleChoiceSegmentedButtonRow {
    options.forEachIndexed { index, label ->
        SegmentedButton(
            shape    = SegmentedButtonDefaults.itemShape(index = index, count = options.size),
            onClick  = { selected = index },
            selected = selected == index,
            label    = { Text(label) }
        )
    }
}
```

---

## Communication

### Badge

```kotlin
BadgedBox(
    badge = {
        if (unreadCount > 0) Badge { Text("$unreadCount") }
        // or: Badge {} for small dot badge
    }
) {
    Icon(Icons.Default.Notifications, contentDescription = "Notifications")
}
```

---

### Progress Indicators

```kotlin
// Indeterminate — unknown duration
CircularProgressIndicator()
LinearProgressIndicator()

// Determinate — known progress (0f–1f)
CircularProgressIndicator(progress = { downloadProgress })
LinearProgressIndicator(progress = { uploadProgress })

// Styled
CircularProgressIndicator(
    progress      = { progress },
    color         = MaterialTheme.colorScheme.primary,
    strokeWidth   = 4.dp
)
```

---

### Snackbar

```kotlin
// Setup in Scaffold
val snackbarHostState = remember { SnackbarHostState() }
val scope = rememberCoroutineScope()

Scaffold(snackbarHost = { SnackbarHost(snackbarHostState) }) { padding ->
    // Content
    Button(onClick = {
        scope.launch {
            snackbarHostState.showSnackbar(
                message     = "Item deleted",
                actionLabel = "Undo",
                duration    = SnackbarDuration.Short
            )
        }
    }) { Text("Delete") }
}
```

---

### Tooltip

```kotlin
// Plain tooltip — brief label
PlainTooltip(tooltip = { Text("Save") }) {
    IconButton(onClick = onSave) {
        Icon(Icons.Default.Save, contentDescription = "Save")
    }
}

// Rich tooltip — more detailed info
RichTooltip(
    title  = { Text("Save to cloud") },
    text   = { Text("Your changes are saved automatically every 5 minutes.") },
    action = { TextButton(onClick = onLearnMore) { Text("Learn more") } }
) {
    IconButton(onClick = {}) {
        Icon(Icons.Default.Info, contentDescription = "Info")
    }
}
```

---

## Containment

### Cards

```kotlin
// Filled card (default)
Card(
    modifier = Modifier.fillMaxWidth(),
    shape    = MaterialTheme.shapes.medium
) {
    Column(modifier = Modifier.padding(Dimens.md)) {
        Text("Title", style = MaterialTheme.typography.titleMedium)
        Text("Description", style = MaterialTheme.typography.bodyMedium)
    }
}

// Elevated card
ElevatedCard(modifier = Modifier.fillMaxWidth()) { /* content */ }

// Outlined card
OutlinedCard(modifier = Modifier.fillMaxWidth()) { /* content */ }

// Clickable card
Card(onClick = { navController.navigate(DetailRoute(item.id)) }) { /* content */ }
```

**Rule**: Cards must never have fixed height — let content drive size.

---

### Dialogs

```kotlin
// AlertDialog — confirmation / destructive action
AlertDialog(
    onDismissRequest = onDismiss,
    title            = { Text("Delete item?") },
    text             = { Text("This action cannot be undone.") },
    confirmButton    = { TextButton(onClick = onConfirmDelete) { Text("Delete") } },
    dismissButton    = { TextButton(onClick = onDismiss) { Text("Cancel") } }
)

// Custom dialog with Card
Dialog(onDismissRequest = onDismiss) {
    Card(shape = MaterialTheme.shapes.extraLarge) {
        Column(modifier = Modifier.padding(24.dp)) {
            Text("Custom Title", style = MaterialTheme.typography.headlineSmall)
            Spacer(Modifier.height(Dimens.md))
            // Custom content
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                TextButton(onClick = onDismiss) { Text("Cancel") }
                Spacer(Modifier.width(Dimens.xs))
                Button(onClick = onConfirm)     { Text("Confirm") }
            }
        }
    }
}
```

---

### Bottom Sheet

```kotlin
var showSheet by remember { mutableStateOf(false) }

if (showSheet) {
    ModalBottomSheet(
        onDismissRequest = { showSheet = false },
        sheetState       = rememberModalBottomSheetState(skipPartiallyExpanded = false)
    ) {
        Column(modifier = Modifier.padding(Dimens.md)) {
            Text("Sheet Title", style = MaterialTheme.typography.titleLarge)
            Spacer(Modifier.height(Dimens.md))
            // Sheet content
        }
    }
}
```

---

### Dividers

```kotlin
HorizontalDivider(
    color     = MaterialTheme.colorScheme.outlineVariant,
    thickness = 1.dp
)

VerticalDivider(
    modifier  = Modifier.height(24.dp),
    color     = MaterialTheme.colorScheme.outlineVariant
)
```

---

## Input

### Chips

```kotlin
// Filter chip — toggle state
var selected by remember { mutableStateOf(false) }
FilterChip(
    selected = selected,
    onClick  = { selected = !selected },
    label    = { Text("Category") },
    leadingIcon = if (selected) {
        { Icon(Icons.Default.Check, null, Modifier.size(FilterChipDefaults.IconSize)) }
    } else null
)

// Assist chip — hint/action
AssistChip(
    onClick     = onOpenMaps,
    label       = { Text("Open Maps") },
    leadingIcon = { Icon(Icons.Default.Place, null) }
)

// Input chip — entered value, dismissible
InputChip(
    selected = true,
    onClick  = {},
    label    = { Text("Tag name") },
    trailingIcon = {
        IconButton(onClick = onRemoveTag, modifier = Modifier.size(InputChipDefaults.AvatarSize)) {
            Icon(Icons.Default.Close, contentDescription = "Remove tag")
        }
    }
)

// Suggestion chip
SuggestionChip(onClick = onAccept, label = { Text("Suggested action") })
```

---

### Text Fields

```kotlin
// Filled text field (default)
var text by remember { mutableStateOf("") }
val isError = text.isNotEmpty() && !text.contains("@")

TextField(
    value            = text,
    onValueChange    = { text = it },
    label            = { Text("Email") },
    placeholder      = { Text("you@example.com") },
    leadingIcon      = { Icon(Icons.Default.Email, null) },
    isError          = isError,
    supportingText   = {
        if (isError) Text("Enter a valid email", color = MaterialTheme.colorScheme.error)
    },
    singleLine       = true,
    keyboardOptions  = KeyboardOptions(keyboardType = KeyboardType.Email, imeAction = ImeAction.Done)
)

// Outlined text field
OutlinedTextField(
    value            = password,
    onValueChange    = { password = it },
    label            = { Text("Password") },
    visualTransformation = PasswordVisualTransformation(),
    trailingIcon     = {
        IconButton(onClick = { showPassword = !showPassword }) {
            Icon(if (showPassword) Icons.Default.VisibilityOff else Icons.Default.Visibility, null)
        }
    },
    singleLine       = true
)
```

---

### Checkbox, Radio, Switch, Slider

```kotlin
// Checkbox
var checked by remember { mutableStateOf(false) }
Checkbox(checked = checked, onCheckedChange = { checked = it })

// With label
Row(
    verticalAlignment = Alignment.CenterVertically,
    modifier = Modifier.clickable { checked = !checked }
) {
    Checkbox(checked = checked, onCheckedChange = null)
    Spacer(Modifier.width(Dimens.xs))
    Text("Accept terms")
}

// Radio button
var selected by remember { mutableStateOf("Option A") }
Column {
    listOf("Option A", "Option B", "Option C").forEach { option ->
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.clickable { selected = option }
        ) {
            RadioButton(selected = selected == option, onClick = { selected = option })
            Spacer(Modifier.width(Dimens.xs))
            Text(option)
        }
    }
}

// Switch
var switchState by remember { mutableStateOf(false) }
Switch(
    checked         = switchState,
    onCheckedChange = { switchState = it },
    thumbContent    = if (switchState) {
        { Icon(Icons.Default.Check, null, Modifier.size(SwitchDefaults.IconSize)) }
    } else null
)

// Continuous slider
var sliderValue by remember { mutableFloatStateOf(0f) }
Slider(
    value         = sliderValue,
    onValueChange = { sliderValue = it },
    valueRange    = 0f..100f
)

// Range slider
var rangeValues by remember { mutableStateOf(20f..80f) }
RangeSlider(
    value         = rangeValues,
    onValueChange = { rangeValues = it },
    valueRange    = 0f..100f
)
```

---

## Navigation Components

### TopAppBar

```kotlin
// Small TopAppBar — standard single-line
TopAppBar(
    title             = { Text("Screen Title") },
    navigationIcon    = {
        IconButton(onClick = onBack) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
        }
    },
    actions = {
        IconButton(onClick = onSearch) { Icon(Icons.Default.Search, "Search") }
        IconButton(onClick = onMore)   { Icon(Icons.Default.MoreVert, "More") }
    },
    colors = TopAppBarDefaults.topAppBarColors(
        containerColor = MaterialTheme.colorScheme.surface
    )
)

// Center-aligned TopAppBar
CenterAlignedTopAppBar(title = { Text("Title") }, navigationIcon = { /* back */ })

// Large TopAppBar — collapses on scroll
val scrollBehavior = TopAppBarDefaults.enterAlwaysScrollBehavior()
Scaffold(
    modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
    topBar   = {
        LargeTopAppBar(
            title          = { Text("Large Title") },
            scrollBehavior = scrollBehavior
        )
    }
) { padding -> /* content with padding */ }
```

---

### Lists

```kotlin
// Basic list item
ListItem(
    headlineContent   = { Text("Item title") },
    supportingContent = { Text("Supporting text") },
    leadingContent    = { Icon(Icons.Default.Person, null) },
    trailingContent   = { Icon(Icons.Default.ChevronRight, null) },
    modifier          = Modifier.clickable { onItemClick() }
)

// LazyColumn with list items
LazyColumn {
    items(items) { item ->
        ListItem(
            headlineContent = { Text(item.title) },
            modifier        = Modifier.clickable { onItemClick(item.id) }
        )
        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
    }
}
```

---

## Rules

- Use `Scaffold` on every screen — it handles `contentPadding`, `snackbarHost`, `topBar`, `bottomBar`, `FAB`
- Only **one** `Button` (filled) per screen section — use `FilledTonalButton`, `OutlinedButton`, or `TextButton` for others
- FAB goes **only** in `Scaffold.floatingActionButton`
- `AlertDialog` for destructive actions — always include a dismiss option
- Navigation bar: max **5 items**, prefer 3–4
- Cards: never fixed height — let content size
- Never nest a scrollable inside a scrollable without `nestedScroll`
- Touch target minimum: **48×48dp** for all interactive elements

---

## Official Docs

- [Compose Material 3 Components](https://developer.android.com/develop/ui/compose/components)
- [M3 Component Guidance](https://m3.material.io/components)
- [Material 3 Adaptive](https://developer.android.com/jetpack/androidx/releases/compose-material3-adaptive)
