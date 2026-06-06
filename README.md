<div align="center">
  <h1>kmp-skills 🤖</h1>
  <p><b>A powerful, version-controlled library of AI Skills for Kotlin Multiplatform.</b></p>
  <p>Teach your AI (Antigravity, Claude, Cursor, Copilot) how to write modern, production-ready KMP code without hallucinations.</p>

  <p>
    <a href="#installation">Installation</a> •
    <a href="#features">Features</a> •
    <a href="#ide-support">IDE Support</a> •
    <a href="#contributing">Contributing</a>
  </p>
</div>

---

## ⚡ What is this?

**kmp-skills** is a monorepo of reusable **AI skills** (structured markdown instructions and modular reference files). 

Instead of copying and pasting the same prompts into every new project, you install this repo globally into your AI assistant. The AI learns exactly how to structure an AGP 9.0+ project, how to scaffold MVI architecture, how to resolve real library versions, and how to audit your Compose UI for Material 3 compliance.

Install it once. Update it everywhere with a single `git pull`.

---

## ✨ Killer Features

### 1. 🏗️ Interactive MVI Project Scaffold
The `kmp-mvi-setup` skill doesn't just dump code. It asks you **8 pre-flight questions** (App Name, Target Platforms, DI, Networking, Serialization, Image Loading, Navigation, Local Storage).
Based on your answers, the AI **dynamically loads only the necessary reference modules** to scaffold your app:
* **Storage:** SQLDelight (KMP) or Room (Android/JVM) or DataStore
* **Network:** Ktor + kotlinx.serialization
* **DI:** Koin + constructor injection patterns
* **Architecture:** Strict `UiState` / `UiEvent` / `UiEffect` data flow with a common `BaseViewModel`.

### 2. 🎨 Material 3 Compliance Auditing
The `material3` skill teaches your AI the complete Material Design 3 spec for Compose Multiplatform. 
It features a **Compliance Audit System**. You can ask the AI to "Audit my UI", and it will generate a 12-category report (Color, Typography, Touch Targets, Contrast, Motion, etc.) grading your app from **A to F** with actionable code fixes. *(Adapted from [hamen/material-3-skill](https://github.com/hamen/material-3-skill))*

### 3. 🛡️ Anti-Hallucination Version Protocol
AIs are notoriously bad at guessing compatible Gradle versions for KMP, AGP, and Compose. The `kmp-versions` skill forces the AI to execute a strict **5-step live fetch protocol** — reading directly from official release pages (JetBrains, Android X, GitHub) before it ever writes a `libs.versions.toml` file.

### 4. 📁 AGP 9.0+ Multi-Module Layout
The single-module `composeApp` structure is dead. The `kmp-project-structure` skill enforces the new, modern KMP layout required for AGP 9.0+: a central `shared/` module surrounded by thin `androidApp/`, `desktopApp/`, and `iosApp/` shells.

---

## 💡 How to Use Your New AI Skills

Once installed, your AI implicitly understands KMP best practices. You can trigger the skills naturally in your conversation.

### Example 1: Scaffolding a new KMP Project
**You say:** 
> *"Create a new KMP project."*

**AI responds:** 
> *"Before I scaffold your KMP project, I need a few details:*
> *1. App name & package*
> *2. Target platforms (Android + Desktop + iOS?)*
> *3. Dependency Injection (Koin or Manual?)*
> *4. Local Storage (SQLDelight or DataStore?)*
> *(...asks 8 pre-flight questions)..."*

Once you answer, the AI will generate the perfect `build.gradle.kts` files, `libs.versions.toml`, and the `UiState`/`UiEvent` boilerplates specifically tailored to your choices.

### Example 2: Material 3 Compliance Audit
**You say:** 
> *"Audit my `HomeScreen.kt` for Material 3 compliance."*

**AI responds:**
```text
╔══════════════════════════════════════════════════════════╗
║          MD3 COMPLIANCE AUDIT — HomeScreen.kt            ║
║          KMP / Compose Multiplatform Edition             ║
╚══════════════════════════════════════════════════════════╝

Score: 8.5 / 10   Grade: B

┌─────────────────────────────────────────────────────────┐
│ CATEGORY RESULTS                                        │
└─────────────────────────────────────────────────────────┘
[✅]  COLOR SYSTEM          [PASS]
[✅]  TYPOGRAPHY            [PASS]
[⚠️]  SHAPE                 [WARN]
[❌]  COMPONENTS            [FAIL]
... (all 12 categories listed)

┌─────────────────────────────────────────────────────────┐
│ FINDINGS & FIXES                                        │
└─────────────────────────────────────────────────────────┘
🔴 COMPONENTS (Fail): The `Icon` on line 45 is missing a `minimumInteractiveComponentSize()`.
🟡 SHAPE (Warn): Hardcoded `RoundedCornerShape(8.dp)`. Use `MaterialTheme.shapes.small`.

Would you like me to apply these fixes?
```

---

## 🚀 Installation

You can install all skills across your IDEs with a single command. 

### Windows (PowerShell)
Open PowerShell and run:
```powershell
irm https://raw.githubusercontent.com/iammohdzaki/kmp-skills/main/get.ps1 | iex
```

### Mac / Linux (Bash)
Open your terminal and run:
```bash
curl -fsSL https://raw.githubusercontent.com/iammohdzaki/kmp-skills/main/get.sh | bash
```

### What the installer does:
1. Clones this repository to `~/.kmp-skills/`
2. Creates **Directory Junctions** (symlinks) into Antigravity/Gemini (zero-copy, updates instantly on `git pull`).
3. Safely appends a specific `<!-- kmp-skills:start -->` block into Claude's global `CLAUDE.md`.
4. Registers a global `kmp-skills` command in your PowerShell profile.

---

## 💻 IDE Support & Strategies

Because every AI tool stores global rules differently, the installer uses specific strategies for each:

| AI Assistant | Strategy | Global Path |
|---|---|---|
| **Antigravity / Gemini CLI** | **Junction** | `~\.gemini\config\skills\<skill>\` |
| **Claude Code CLI** | **Append** | `~\.claude\CLAUDE.md` |
| **Windsurf** | Append | `~\.codeium\windsurf\memories\global_rules.md` |
| **Cursor** | Copy (`.mdc`) | `~\.kmp-skills\cursor-rules\` *(Junction this into project `.cursor/rules/`)* |
| **GitHub Copilot (VS Code)** | Copy | `%APPDATA%\Code\User\prompts\kmp-skills.instructions.md` |

---

## 🛠️ CLI Usage

Once installed, you can manage your skills from any terminal using the `kmp-skills` command.

```powershell
# See all available skills in the library
kmp-skills list

# Check sync status across all installed IDEs
kmp-skills status -Target all

# Pull the latest community updates from GitHub and re-sync your IDEs
kmp-skills update -Target all

# Install specific skills to a local Cursor/Windsurf project
kmp-skills install -Target cursor -Project D:\Projects\MyNextGreatApp

# Uninstall from a specific IDE
kmp-skills uninstall -Target claude
```

---

## 🤝 Contributing

This is a community-driven library. If a new library becomes popular in KMP, or an existing one changes its API, we want to know!

1. Check out the [CONTRIBUTING.md](CONTRIBUTING.md) for our skill writing guidelines.
2. Ensure you use the `FETCH` protocol for versions instead of hardcoding them.
3. Submit a Pull Request!

---

## 📜 License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.
