# Sync local main to origin/main (LP更新2 などリモート最新と一致)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

if (-not (Test-Path (Join-Path $Root ".git"))) {
    throw "Not a git repository: $Root"
}

Write-Host "Fetching origin/main..."
git fetch origin main

Write-Host "Checking out main..."
git checkout main

Write-Host "Resetting to origin/main (discards local commits on main)..."
git reset --hard origin/main

$status = git status --porcelain
if ($status) {
    Write-Host "Removing untracked files..."
    git clean -fd
}

Write-Host ""
Write-Host "Done. Current commit:"
git log -1 --oneline
Write-Host ""
Write-Host "LP更新2 の目安: lib/widgets/edit_device_appearance_sheet.dart が存在すること"
$marker = Join-Path $Root "lib\widgets\edit_device_appearance_sheet.dart"
if (Test-Path $marker) {
    Write-Host "  OK: edit_device_appearance_sheet.dart あり"
} else {
    throw "edit_device_appearance_sheet.dart がありません。リモートと一致していない可能性があります。"
}
