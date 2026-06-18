# JSON Young

A macOS desktop app for validating and pretty-printing JSON, built with Swift and SwiftUI.

## Features

- **Live validation** — the footer shows whether the current input is valid JSON in real time.
- **Pretty-print** — formats JSON with consistent indentation in place.
- **Syntax highlighting** — colour-coded JSON tokens in the editor.
- **Keyboard shortcut** — `⌘⇧F` to format without reaching for the mouse.

## Install

### Homebrew (recommended)

```bash
brew tap panutat-p/tap
brew install --cask json-young
```

To upgrade later:

```bash
brew upgrade --cask json-young
```

To uninstall:

```bash
brew uninstall --cask json-young
```

### Manual

1. Download `JSON_Young.dmg` from the [latest release](https://github.com/panutat-p/json-young/releases/latest)
2. Open the DMG and drag **JSON Young.app** to **Applications**
3. Launch JSON Young from Applications or Spotlight

> If macOS shows a Gatekeeper warning, run:
> ```bash
> xattr -cr "/Applications/JSON Young.app"
> ```

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.9+
- [Task](https://taskfile.dev/) (recommended for local builds)

## Quick start

```bash
task dev
```

`task dev` builds a debug `.app` bundle and opens it with `open`, which is required for the GUI window to appear reliably.

The built app is at `.build/JSON Young.app`.

## Build commands

| Command | Description |
|---------|-------------|
| `task dev` | Build Debug and launch the app |
| `task release` | Build Release and create `JSON_Young.dmg` in the project root |
| `task test` | Run unit tests via Swift Package Manager |
| `task icons` | Generate `AppIcon.png` and build `AppIcon.icns` |
| `task clean` | Remove Swift build artifacts, app bundle, and DMG |

### Swift Package Manager

```bash
swift build            # debug
swift build -c release # release
swift test             # run tests
```

Raw binary (GUI window may not appear when launched directly from Terminal):

```bash
swift run json-linter
```

## Usage

1. Paste or type JSON into the editor.
2. The footer shows whether the input is valid JSON.
3. Click **Format** or press `⌘⇧F` to pretty-print the JSON in place.

### Example valid JSON

```json
{"name":"Alice","items":[1,2,3]}
```

After formatting:

```json
{
  "name" : "Alice",
  "items" : [
    1,
    2,
    3
  ]
}
```

### Example invalid JSON

```json
{"name": "Alice",}
```

The footer will show a parse error message.

## Release pipeline

Releases are fully automated via GitHub Actions. Pushing a version tag triggers the entire pipeline — building, packaging, publishing, and updating the Homebrew formula — without any manual steps.

### How to release

```bash
git tag v1.2.0
git push origin v1.2.0
```

### What happens automatically

```
git push origin v1.2.0
        │
        ▼
release.yml (this repo) — runs on macos-latest
  1. Build JSON Young.app   Scripts/bundle-app.sh release
  2. Package JSON_Young.dmg Scripts/create-dmg.sh
  3. Compute SHA256          shasum -a 256 JSON_Young.dmg
  4. Publish GitHub Release  JSON_Young.dmg attached, SHA256 in release notes
  5. Dispatch to tap         POST /repos/panutat-p/homebrew-tap/dispatches
        │
        │  payload: { cask, version, sha256 }
        ▼
update-tap.yml (panutat-p/homebrew-tap)
  6. Patch Casks/json-young.rb  version + sha256 replaced via sed
  7. Commit and push             "chore: bump json-young to v1.2.0"
```

After step 7, `brew upgrade --cask json-young` will pull the new version for all users.

### Workflow file

`.github/workflows/release.yml` — triggered on `v*.*.*` tag push.

| Step | Tool | Notes |
|------|------|-------|
| Build app | `Scripts/bundle-app.sh release` | Compiles with `swift build -c release`, bundles `Info.plist` and icon |
| Create DMG | `Scripts/create-dmg.sh` | Adds Applications symlink, compresses with UDZO |
| Compute SHA256 | `shasum -a 256` | Written to `GITHUB_OUTPUT` for downstream steps |
| GitHub Release | `softprops/action-gh-release@v2` | Creates release, attaches DMG, sets release notes |
| Tap dispatch | `peter-evans/repository-dispatch@v3` | Fires `update-cask` event on `panutat-p/homebrew-tap` |

### Secrets

| Secret | Repo | Purpose |
|--------|------|---------|
| `TAP_GITHUB_TOKEN` | `json-young` | Classic PAT with `repo` scope — authorises the `repository_dispatch` call to `homebrew-tap` |
| `GITHUB_TOKEN` | `homebrew-tap` | Auto-injected by GitHub Actions — used by `update-tap.yml` to push the formula bump |

### Homebrew tap

The shared tap repo is [panutat-p/homebrew-tap](https://github.com/panutat-p/homebrew-tap).

```
homebrew-tap/
  Casks/
    json-young.rb    ← patched automatically on each release
    hyperzen.rb
  .github/workflows/
    update-tap.yml   ← receives dispatch, patches formula, pushes bump
```

## Project structure

```
Sources/            App source (SwiftUI views, JSON linting logic)
Tests/              Unit tests
Scripts/            bundle-app.sh, create-dmg.sh, build-app-icon.sh
Resources/          Bundled assets
.github/workflows/  release.yml — automated build, release, and tap update
taskfile.yaml       Task definitions for build and release
Package.swift       Swift package manifest
```

## License

Not specified.
