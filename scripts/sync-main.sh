#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not a git repository: $ROOT" >&2
  exit 1
fi

echo "Fetching origin/main..."
git fetch origin main

echo "Checking out main..."
git checkout main

echo "Resetting to origin/main (discards local commits on main)..."
git reset --hard origin/main

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Removing untracked files..."
  git clean -fd
fi

echo ""
echo "Done. Current commit:"
git log -1 --oneline
echo ""
echo "LP更新2 の目安: lib/widgets/edit_device_appearance_sheet.dart が存在すること"
if [[ -f lib/widgets/edit_device_appearance_sheet.dart ]]; then
  echo "  OK: edit_device_appearance_sheet.dart あり"
else
  echo "  WARN: edit_device_appearance_sheet.dart がありません" >&2
  exit 1
fi
