param(
    [string]$CommitMessage = "Auto-commit large change",
    [int]$Threshold = 100,
    [string]$Remote = "origin",
    [string]$Branch = ""
)

$ErrorActionPreference = "Stop"

function Get-CurrentBranch {
    $name = git branch --show-current
    if (-not $name) {
        throw "Unable to determine current branch."
    }
    return $name.Trim()
}

function Get-HeadRef {
    git rev-parse --verify HEAD 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return "HEAD"
    }

    return "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
}

function Get-ChangedLineCount {
    param(
        [string]$BaseRef
    )

    $numstat = git diff --cached --numstat $BaseRef
    $total = 0

    foreach ($line in $numstat) {
        if (-not $line) {
            continue
        }

        $parts = $line -split "`t"
        if ($parts.Length -lt 3) {
            continue
        }

        $added = $parts[0]
        $deleted = $parts[1]

        if ($added -match '^\d+$') {
            $total += [int]$added
        }

        if ($deleted -match '^\d+$') {
            $total += [int]$deleted
        }
    }

    return $total
}

git rev-parse --is-inside-work-tree | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Current directory is not a Git repository."
}

git add -A
if ($LASTEXITCODE -ne 0) {
    throw "git add -A failed."
}

$baseRef = Get-HeadRef
$changedLines = Get-ChangedLineCount -BaseRef $baseRef

if ($changedLines -lt $Threshold) {
    git restore --staged . 2>$null
    Write-Host "Changed lines: $changedLines. Threshold $Threshold not met. No commit created."
    exit 0
}

git status --short

$hasStagedChanges = git diff --cached --name-only
if (-not $hasStagedChanges) {
    Write-Host "No staged changes found after git add -A. No commit created."
    exit 0
}

git commit -m $CommitMessage
if ($LASTEXITCODE -ne 0) {
    throw "git commit failed."
}

if (-not $Branch) {
    $Branch = Get-CurrentBranch
}

git push $Remote $Branch
if ($LASTEXITCODE -ne 0) {
    Write-Error "Push failed. The commit was created locally but was not pushed to $Remote/$Branch."
    exit 1
}

Write-Host "Committed and pushed $changedLines changed lines to $Remote/$Branch."
