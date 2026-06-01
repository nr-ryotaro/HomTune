# HomTune Web UI プレビュー用ビルド（API キー不要・ダミーデータ）
$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

Write-Host "Building HomTune Web UI preview..." -ForegroundColor Cyan
flutter pub get
flutter build web --release --no-wasm-dry-run

Write-Host ""
Write-Host "Done. Output: build/web/" -ForegroundColor Green
Write-Host "Local preview: flutter run -d chrome" -ForegroundColor Yellow
Write-Host "Deploy: drag build/web to https://app.netlify.com/drop" -ForegroundColor Yellow
