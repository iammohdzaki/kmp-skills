# Contributing to kmp-skills

Thank you for wanting to contribute! kmp-skills is a community-maintained library of AI skills
for Kotlin Multiplatform development. All skill additions, corrections, and improvements are welcome.

---

## What is a "skill"?

A skill is a folder containing:

```
skills/<category>/<skill-name>/
    SKILL.md              <- required: main instructions for the AI
    references/           <- optional: deeper reference files the AI reads on demand
        topic-name.md
```

The AI reads `SKILL.md` to understand the skill. It reads files in `references/` only when
a specific topic is needed (lazy loading — keeps context lean).

---

## Adding a new skill

### 1. Copy the template

```bash
cp -r skills/_template skills/<category>/<your-skill-name>
```

Categories so far: `create-project`, `design-system`. Add a new category folder if yours doesn't fit.

### 2. Fill in SKILL.md

The YAML frontmatter at the top is required:

```yaml
---
name: your-skill-name          # kebab-case, unique across all skills
category: create-project       # folder category
description: >
  One or two sentence description. The AI uses this to decide when to load the skill.
  Be specific about what problem this skill solves.
targets:
  - antigravity
  - claude
  - cursor
  - windsurf
sources:
  - https://official-docs-url.com   # always link official sources
---
```

### 3. Write the skill content

Follow these principles:

- **Generic** — no references to specific user projects or personal config
- **Source-linked** — every fact should point to an official doc URL
- **Versioning-safe** — never hardcode library versions; use `FETCH_FROM_OFFICIAL_SOURCE`
  and point to the official releases page
- **KMP-first** — all code examples use `commonMain` patterns unless platform-specific
- **Compose-only** — no Flutter, no web CSS, no `@material/web`

### 4. Add reference files (optional)

If your skill is large, break it into a main `SKILL.md` (overview + decision tree) and
reference files the AI reads on demand:

```
references/
    setup.md          <- detailed setup instructions
    patterns.md       <- code patterns and examples
    pitfalls.md       <- common mistakes and fixes
```

Reference your files from SKILL.md like:
```markdown
Full details: [references/setup.md](references/setup.md)
```

### 5. Bump the version

Edit `VERSION` (semver):
- Patch (`1.0.0 -> 1.0.1`): fixing a bug, correcting a version number, small wording fix
- Minor (`1.0.0 -> 1.1.0`): new skill, new reference file, significant content addition
- Major (`1.0.0 -> 2.0.0`): breaking change to skill structure or install format

Add an entry to `CHANGELOG.md`.

### 6. Open a pull request

- PR title: `[category] skill-name: short description`
- Describe what the skill covers and why it's useful
- Mention any official sources you referenced

---

## Updating an existing skill

If a library releases a new version that changes how things work:

1. Update the affected `SKILL.md` or reference file
2. If a **breaking change** (e.g. deprecated API, new required plugin), add it to the
   `Known Breaking Changes` table if one exists in the skill
3. Bump `VERSION` (patch for fixes, minor for significant changes)
4. Add a line to `CHANGELOG.md`

---

## Skill quality checklist

Before submitting a PR, verify:

- [ ] YAML frontmatter has `name`, `category`, `description`, `targets`, `sources`
- [ ] No hardcoded library versions (use `FETCH_FROM_OFFICIAL_SOURCE`)
- [ ] Every version number links to the official releases page
- [ ] No references to specific projects or personal directories
- [ ] Code examples compile (mentally check imports and syntax)
- [ ] `references/` files are linked from `SKILL.md`
- [ ] `VERSION` bumped and `CHANGELOG.md` updated

---

## Repository structure

```
kmp-skills/
    skills/
        _template/          <- copy this to start a new skill
        create-project/
            kmp-mvi-setup/
            kmp-versions/
            kmp-project-structure/
        design-system/
            material3/
    get.ps1                 <- single-command installer (bootstrap)
    install.ps1             <- full installer (run after clone)
    VERSION                 <- semver e.g. 1.0.0
    CHANGELOG.md
    CONTRIBUTING.md
    LICENSE                 <- MIT
    README.md
```

---

## Code of conduct

- Be respectful and constructive in reviews
- Focus on correctness and clarity
- Credit official sources — don't invent API signatures from memory
- If unsure about a version or API, leave a `<!-- TODO: verify -->` comment rather than guessing

---

## Questions?

Open a GitHub issue with the `question` label.
