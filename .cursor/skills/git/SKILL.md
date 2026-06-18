---
name: git
description: Git workflow for json-swift (JSON Young macOS app) — use git switch, check branch with git status, avoid pushing to main, and use conventional branch names and commit messages. Use when creating branches, committing, pushing, or any git operation in this repo.
---

# Git workflow (json-swift)

## Project context

- **Repo**: `json-swift` — a macOS JSON linter built with Swift, SwiftUI, and Swift Package Manager.
- **App name**: JSON Young (`.app` bundle under `.build/JSON Young.app`).
- **Layout**:
  - `Sources/JSONLinter/` — SwiftUI app (views, view model)
  - `Sources/JSONLinterLib/` — shared JSON parsing/formatting logic
  - `Tests/JSONLinterTests/` — unit tests
  - `Scripts/` — bundling, DMG, and icon scripts
  - `Resources/` — `Info.plist`, assets
- **Common commands**: `task run`, `task test`, `task release`, `swift test`, `swift build`

## Rules

- Prefer **`git switch`** over `git checkout` (branches, new branches, restore files).
- **Always run `git status`** before branch-changing or push operations to confirm the current branch and staged files.
- **Do not push to `main` directly.** Work on a feature branch, push that branch, and open a PR.
- Use **conventional branch names** and **conventional commit messages**.
- **Only commit when asked.** Do not create commits proactively unless the user explicitly requests it.

## Branch names

Use lowercase, hyphenated suffixes:

| Prefix      | When                                                |
| ----------- | --------------------------------------------------- |
| `feat/`     | New feature or user-facing behavior                 |
| `fix/`      | Bug fix                                             |
| `refactor/` | Code change without behavior change                 |
| `chore/`    | Tooling, deps, config, version bumps                |
| `test/`     | Tests only                                          |
| `docs/`     | Documentation only                                  |
| `style/`    | Formatting, whitespace, lint-only (no logic change) |
| `perf/`     | Performance improvement                             |
| `build/`    | Build system, bundler, or deploy config             |
| `revert/`   | Revert a previous change                            |

Examples:

- `feat/format-keyboard-shortcut`
- `fix/footer-error-message-truncation`
- `refactor/extract-json-linter-lib`
- `chore/update-app-icon-scripts`

Create and switch:

```bash
git status
git switch -c feat/short-description
```

Switch to an existing branch:

```bash
git status
git switch feat/short-description
```

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>: <short summary>

Optional body explaining why, not just what.
```

Common types: `feat`, `fix`, `refactor`, `chore`, `test`, `docs`, `style`, `perf`, `build`, `revert`.

Examples:

```
feat: add keyboard shortcut for format action

fix: show parse error line number in footer

refactor: move JSON validation into JSONLinterLib

test: add cases for trailing-comma invalid JSON

chore: update bundle script for release builds

build: bump minimum macOS target in Package.swift

docs: document task release workflow in README
```

Commit:

```bash
git status
git add <relevant-files>
git commit -m "$(cat <<'EOF'
feat: short summary here

Optional body.
EOF
)"
```

## Push

```bash
git status   # confirm not on main
git push -u origin HEAD
```

If currently on `main`, create and switch to a branch first — never push commits directly to `main`.

## Pre-commit checks

Before committing Swift changes, run tests when the change affects logic:

```bash
swift test
# or
task test
```

For UI or bundling changes, verify the app launches:

```bash
task run
```

## Quick checklist

- [ ] `git status` — correct branch, only intended files staged
- [ ] Branch name uses conventional prefix (`feat/`, `fix/`, `refactor/`, …)
- [ ] Commit message uses conventional type (`feat:`, `refactor:`, …)
- [ ] Push targets a feature branch, not `main`
- [ ] `swift test` passes when logic changed

## Related skills

- PR creation and review: [github/SKILL.md](../github/SKILL.md) — PR **titles** use plain English, not conventional commit prefixes.
