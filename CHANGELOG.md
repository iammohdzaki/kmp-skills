# Changelog

All notable changes to kmp-skills are documented here.
Format: [version] — date — summary

---

## [1.0.0] — 2026-06-06

### Added
- `create-project/kmp-mvi-setup` — Interactive MVI project scaffold skill with Module Loader
  - `references/mvi-patterns.md` — MVI contracts, BaseViewModel, best practices, feature checklist
  - `references/di-options.md` — Koin DI setup for Android + Desktop
  - `references/network-ktor.md` — Ktor HTTP client, expect/actual engines, repository pattern
  - `references/serialization.md` — kotlinx.serialization setup, Ktor integration, DI wiring
  - `references/navigation.md` — Type-safe navigation-compose with @Serializable routes
  - `references/image-loading.md` — Coil 3 + Landscapist for KMP
  - `references/storage-datastore.md` — multiplatform-settings + AndroidX DataStore
  - `references/storage-sqldelight.md` — SQLDelight KMP database (recommended)
  - `references/storage-room.md` — Room for Android/JVM projects
- `create-project/kmp-versions` — Anti-hallucination version skill (5-step live fetch protocol)
- `create-project/kmp-project-structure` — New multi-module layout (shared/ + androidApp/), AGP 9+
- `design-system/material3` — Material 3 KMP skill (adapted from hamen/material-3-skill)
  - Full MD3 token system, 30+ components, adaptive layout, motion, accessibility
  - MD3 Compliance Audit system (12-category report with score A–F)
  - 6 reference files: color, theming, typography, components, layout, navigation
