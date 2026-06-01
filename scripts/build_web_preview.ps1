# HomTune Web UI プレビュー用ビルド（Netlify Drop 向け）
# 重要: ドラッグするのは build/web の「中身」または homtune-web-deploy.zip
#        プロジェクト直下の web/ フォルダはソース用で動きません
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "Building HomTune Web UI preview..." -ForegroundColor Cyan
flutter pub get
flutter build web --release --base-href=/ --pwa-strategy=none --no-wasm-dry-run

$outDir = Join-Path $ProjectRoot "build\web"
$required = @(
    "index.html",
    "main.dart.js",
    "flutter_bootstrap.js",
    "flutter.js",
    "canvaskit"
)

$missing = @()
foreach ($name in $required) {
    $path = Join-Path $outDir $name
    if (-not (Test-Path $path)) {
        $missing += $name
    }
}
if ($missing.Count -gt 0) {
    Write-Host "Build failed validation. Missing:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" }
    exit 1
}

# Netlify 用ヘッダ（MIME）
$headersSrc = Join-Path $ProjectRoot "web\netlify_headers"
$headersDst = Join-Path $outDir "_headers"
@"
/*.js
  Content-Type: application/javascript; charset=utf-8

/*.wasm
  Content-Type: application/wasm

/*.json
  Content-Type: application/json; charset=utf-8
"@ | Set-Content -Path $headersDst -Encoding UTF8

$readme = @"
HomTune Web デプロイ用フォルダ
==============================

【Netlify Drop でアップロードするもの】
  このフォルダ (build/web) 全体をドラッグしてください。

【アップロードしてはいけないもの】
  x プロジェクト直下の web/  （ソースのみ・main.dart.js なし → 白画面）
  x HomTune リポジトリ全体

【必須ファイル（このフォルダに含まれていること）】
  - main.dart.js
  - flutter_bootstrap.js
  - canvaskit/
  - assets/

URL 例: https://xxxx.netlify.app
"@
$readme | Set-Content -Path (Join-Path $outDir "NETLIFY_DROP_README.txt") -Encoding UTF8

$zipPath = Join-Path $ProjectRoot "dist\homtune-web-deploy.zip"
$distDir = Join-Path $ProjectRoot "dist"
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}
Compress-Archive -Path (Join-Path $outDir "*") -DestinationPath $zipPath -Force

$mainJsMb = [math]::Round((Get-Item (Join-Path $outDir "main.dart.js")).Length / 1MB, 2)
Write-Host ""
Write-Host "Build OK ($mainJsMb MB main.dart.js)" -ForegroundColor Green
Write-Host ""
Write-Host "Deploy (choose one):" -ForegroundColor Yellow
Write-Host "  1. Drag folder:  $outDir"
Write-Host "  2. Drag zip:     $zipPath"
Write-Host "  3. Local test:   flutter run -d chrome"
Write-Host ""
Write-Host "Do NOT upload the source web/ folder at repo root." -ForegroundColor Red
