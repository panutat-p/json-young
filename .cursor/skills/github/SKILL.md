---
name: gh-pr
description: Use GitHub CLI (gh) to create a PR, review an existing PR, or add/update details on a PR for json-swift. Use when the user asks to open a PR, create a pull request, review a PR, update PR description, add reviewers, or any gh pr workflow.
disable-model-invocation: true
---

# GitHub CLI PR Workflow (json-swift)

## Before Any Command

Always verify authentication first:

```bash
gh auth status
```

If not authenticated, run `gh auth login` before proceeding.

## Create a PR

### PR Title

Use a **plain English sentence** that describes the change for a human reader.

- Good: `Add keyboard shortcut for JSON formatting`
- Good: `Fix footer not updating after paste`
- Bad: `feat: add keyboard shortcut`
- Bad: `fix(json-linter): footer update`

Do **not** use conventional commit prefixes (`feat:`, `fix:`, `chore:`, etc.) or scoped commit formats (`fix(scope): ...`) in PR titles.

### PR Body

Pick the template that matches the change. Do **not** include a Test Plan section.

#### Bug fix

1. **Problem** — What is broken? Where does it show up in the app?
2. **Root Cause** — Why it happens (SwiftUI state, JSON parsing edge case, bundle config, etc.)
3. **Solution** — What was changed and why that fixes it

#### New feature

1. **Overview** — What the feature does and why it is needed
2. **Implementation** — How it was built: key files, approach, and notable design choices

Optional: add a diagram (mermaid) when the change involves data flow, view-model state, or build pipeline steps.

### Create PR

1. Create PR with title and body (bug fix example):

   ```bash
   gh pr create --title "Fix footer not updating after paste" --body "$(cat <<'EOF'
   ## Problem

   After pasting JSON into the editor, the footer still shows the previous validation status until the user types another character.

   ## Root Cause

   - `LinterViewModel` only re-validated on `onChange` of typed input
   - Paste events updated the text binding without triggering validation

   ## Solution

   - Call `validate()` from the paste handler in `ContentView`
   - Extract shared validation trigger so typing and paste use the same path
   EOF
   )"
   ```

   New feature example:

   ```bash
   gh pr create --title "Add keyboard shortcut for JSON formatting" --body "$(cat <<'EOF'
   ## Overview

   Users can format JSON in the editor with ⌘⇧F instead of using the menu.

   ## Implementation

   - Register `formatJSON` in `KeyboardShortcuts.swift`
   - Wire the shortcut to `LinterViewModel.format()` from `ContentView`
   - Reuse existing formatting logic so menu and shortcut stay in sync
   EOF
   )"
   ```

2. Add reviewers or assignees (optional):

   ```bash
   gh pr create --title "..." --body "..." --reviewer handle1,handle2 --assignee "@me"
   ```

3. Draft PR (not ready for review):

   ```bash
   gh pr create --draft --title "..." --body "..."
   ```

4. Autofill title and body from commit messages (only when appropriate):

   ```bash
   gh pr create --fill
   ```

   After `--fill`, **edit the title and body** to match the conventions above. Commit messages often use conventional prefixes; PR titles and bodies should not.

## View / Review a PR

```bash
# View PR in terminal
gh pr view [number]

# Open PR in browser
gh pr view [number] --web

# List open PRs
gh pr list

# View PR diff
gh pr diff [number]

# View PR checks / CI status
gh pr checks [number]

# Watch checks until they finish
gh pr checks [number] --watch
```

## Add or Update PR Details

```bash
# Set title
gh pr edit [number] --title "new title"

# Replace body
gh pr edit [number] --body "new body text"

# Add reviewers
gh pr edit [number] --add-reviewer handle1,handle2

# Remove reviewers
gh pr edit [number] --remove-reviewer handle1

# Add labels
gh pr edit [number] --add-label "bug,enhancement"

# Remove labels
gh pr edit [number] --remove-label "needs-triage"

# Mark ready for review (un-draft)
gh pr ready [number]

# Convert back to draft
gh pr ready [number] --undo
```

## Approve / Request Changes

```bash
# Approve
gh pr review [number] --approve

# Request changes with comment
gh pr review [number] --request-changes --body "Please fix X"

# Leave a comment review
gh pr review [number] --comment --body "Looks good overall, minor nits inline"
```

## Merge a PR

```bash
# Merge commit
gh pr merge [number] --merge

# Squash merge
gh pr merge [number] --squash

# Rebase merge
gh pr merge [number] --rebase

# Auto-merge when checks pass
gh pr merge [number] --auto --squash

# Delete branch after merge
gh pr merge [number] --squash --delete-branch
```

## Tips

- Omit `[number]` to target the PR for the current branch.
- Use `--web` on any command to open that PR in the browser.
- `gh pr view --json title,body,reviews,reviewRequests` for structured data.
- When updating an existing PR with `gh pr edit --body`, keep the same template sections (bug fix: Problem, Root Cause, Solution; new feature: Overview, Implementation).
