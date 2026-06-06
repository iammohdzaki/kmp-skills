# kmp-skills

> A personal, version-controlled library of AI skills for Kotlin Multiplatform projects.
> Install once — update everywhere with a single `git pull`.

---

## What is this?

`kmp-skills` is a monorepo of reusable **AI skills** (structured markdown guides) for:
- Setting up KMP + MVI projects from scratch
- Applying Material 3 design correctly in Compose Multiplatform
- Resolving compatible KMP/AGP/CMP version combinations
- Structuring the new AGP 9+ multi-module project layout

Skills are written as `SKILL.md` files that AI assistants (Antigravity, Claude, Cursor, Windsurf)
read to understand best practices, architecture patterns, and step-by-step workflows.

---

## Skills

| Category | Skill | Description |
|---|---|---|
| `create-project` | `kmp-mvi-setup` | Interactive MVI project scaffold with 8 module choices |
| `create-project` | `kmp-versions` | Anti-hallucination version resolver (live fetch protocol) |
| `create-project` | `kmp-project-structure` | New AGP 9+ multi-module layout (shared/ + androidApp/) |
| `design-system` | `material3` | Full MD3 for KMP, compliance audit system (12 categories) |

---

## Installation

### Requirements
- PowerShell 5.1+ (built into Windows)
- Git (for the `update` command)

### Install to Antigravity (global, junction-based)

```powershell
.\install.ps1
```

This creates **directory junctions** from Antigravity's skills folder into this repo.
After this, `git pull` in this repo is all you ever need to update. No re-install.

### Install to all IDEs

```powershell
.\install.ps1 install -Target all
```

### Install to a specific project (Cursor / Windsurf / Claude)

```powershell
.\install.ps1 install -Target cursor   -Project D:\Projects\MyApp
.\install.ps1 install -Target windsurf -Project D:\Projects\MyApp
.\install.ps1 install -Target claude   -Project D:\Projects\MyApp
```

---

## Commands

```powershell
# Check installed version and sync status across all IDEs
.\install.ps1 status -Target all

# Pull latest from git and re-sync everything
.\install.ps1 update -Target all

# Install only one category
.\install.ps1 install -Target antigravity -Category create-project

# Install only one skill
.\install.ps1 install -Target antigravity -SkillName kmp-mvi-setup

# See all available skills
.\install.ps1 list

# Remove from an IDE
.\install.ps1 uninstall -Target cursor -Project D:\Projects\MyApp
```

---

## How Updates Work

### Antigravity (junction strategy — zero effort updates)

```
kmp-skills/skills/create-project/kmp-mvi-setup/
         ↑ (junction)
~/.gemini/config/skills/kmp-mvi-setup   ← Antigravity reads this
```

When you `git pull` in `D:\Projects\kmp-skills`, Antigravity immediately sees the updated
skills — no re-install needed. The junction points directly into the repo.

### Claude / Cursor / Windsurf (copy + hash strategy)

These IDEs don't reliably follow directory junctions. Skills are **copied** and tracked with
a content hash manifest (`.kmp-skills-manifest.json`) in the install directory.

To update after a `git pull`:

```powershell
.\install.ps1 update -Target all
```

This runs `git pull`, detects which skills changed (via hash comparison), and re-copies only
the changed ones. Unchanged skills are skipped.

### Status check — see what's out of date

```powershell
.\install.ps1 status -Target all
```

Output example:
```
── Status: antigravity  →  C:\Users\you\.gemini\config\skills
   ✓ Version: 1.0.0  (up to date)
   ✓ kmp-mvi-setup   [junction → D:\Projects\kmp-skills\skills\create-project\kmp-mvi-setup]
   ✓ kmp-versions    [junction → D:\Projects\kmp-skills\skills\create-project\kmp-versions]

── Status: cursor  →  C:\Users\you\.cursor\rules
   ⚠ Version: installed=1.0.0  repo=1.1.0  (run: .\install.ps1 update -Target cursor)
   ✓ kmp-mvi-setup  [copy — in sync]
   ⚠ material3      [copy — OUTDATED — run update]
```

---

## Adding New Skills

1. Copy the `skills/_template/` folder
2. Rename it to your skill name under the right category
3. Edit `SKILL.md`
4. Bump `VERSION` and add a line to `CHANGELOG.md`
5. Run `.\install.ps1 update -Target all`

```
skills/
├── _template/
│   └── SKILL.md          ← starter template
├── create-project/
│   ├── kmp-mvi-setup/
│   │   ├── SKILL.md
│   │   └── references/   ← optional module reference files
│   ├── kmp-versions/
│   └── kmp-project-structure/
└── design-system/
    └── material3/
        ├── SKILL.md
        └── references/
```

---

## IDE Global Install Paths

| IDE | Strategy | Global Path |
|---|---|---|
| **Antigravity** | Junction (auto-update on git pull) | `~\.gemini\config\skills\` |
| **Claude Code** | Copy | `~\.claude\skills\` |
| **Cursor** | Copy `.mdc` files | `~\.cursor\rules\` |
| **Windsurf** | Copy `.md` files | `~\.codeium\windsurf\rules\` |

---

## Version History

See [CHANGELOG.md](CHANGELOG.md).
