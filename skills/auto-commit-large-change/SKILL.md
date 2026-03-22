---
name: auto-commit-large-change
description: Use this skill when working inside the MWL-used repository and the user wants large edits to be committed and pushed automatically after cumulative changes reach 100 lines or more.
---

# Auto Commit Large Change

Use this skill only in the repository `d:\MWL-used\MWL-used`.

## Purpose

When the working tree reaches at least 100 changed lines, commit and push the change set to GitHub instead of leaving a large uncommitted diff behind.

This skill is for Codex-assisted work in this repository. It does not watch the filesystem in the background and it does not commit edits made outside the current session unless explicitly asked.

## Threshold

- Treat `added + deleted` lines as the total change size.
- The threshold is `100` lines by default.
- Measure the diff against `HEAD`.

## Required Workflow

1. Finish the requested edit and verify the result as usual.
2. Check the total changed lines by running `scripts/commit_if_large_change.ps1`.
3. If the threshold is met, let the script stage all changes, create a commit, and push the current branch to `origin`.
4. If the threshold is not met, do not create an automatic commit.

## Commit Rules

- Prefer a direct commit message derived from the task, for example `Add auto commit skill for large changes`.
- Do not squash unrelated user changes into an automatic commit if they clearly belong to a different task.
- If the working tree includes risky or partially validated edits, finish validation first. This skill does not override correctness.

## Command

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\auto-commit-large-change\scripts\commit_if_large_change.ps1 -CommitMessage "<message>"
```

Optional parameters:

- `-Threshold 100`
- `-Remote origin`
- `-Branch main`

## Failure Handling

- If push fails because of authentication, SSH, or network problems, report the exact failure and keep the commit local.
- If there is no upstream branch, push with the explicit remote and branch.
- If there are no changes, exit without creating an empty commit.

## Safety Notes

- The script stages all current changes before committing.
- Do not run it when the user intentionally has a mixed staged and unstaged state they want preserved.
- If that situation exists, ask before proceeding.
