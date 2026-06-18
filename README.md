# JSON Linter

A macOS desktop app for validating and pretty-printing JSON, built with Swift and SwiftUI.

## Requirements

- macOS 14 or later
- Swift 5.9+

## Build and run

```bash
task dev
```

`task dev` builds a debug `.app` bundle and opens it with macOS `open`, which is required for the GUI window to appear reliably.

Release `.dmg` for distribution:

```bash
task release
```

This produces `JSON_Young.dmg` in the project root.

Raw binary (window may not appear when launched from Terminal):

```bash
swift run json-linter
```

## Tests

```bash
swift test
```

## Usage

1. Paste or type JSON into the editor.
2. The footer shows whether the input is valid JSON.
3. Click **Format** (or press `⌘⇧F`) to pretty-print the JSON in place.

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
