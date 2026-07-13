# HomTune Web UI プレビュー用ビルド（Netlify 向け）
# 成果物: build/web/ と dist/homtune-web-deploy.zip
#
# Netlify Drop: build/web フォルダ全体、または zip をドラッグ
# 禁止: リポジトリ直下の web/ のみ（main.dart.js が無く白画面になる）
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

function Get-AppVersion {
    $pubspec = Get-Content (Join-Path $ProjectRoot "pubspec.yaml") -Raw
    if ($pubspec -match 'version:\s*([^\s+]+)') {
        return $Matches[1]
    }
    return "unknown"
}

Write-Host "Building HomTune Web UI preview for Netlify..." -ForegroundColor Cyan
flutter pub get
flutter build web --release --base-href=/ --pwa-strategy=none --no-wasm-dry-run

$outDir = Join-Path $ProjectRoot "build\web"
$required = @(
    "index.html",
    "main.dart.js",
    "flutter_bootstrap.js",
    "flutter.js",
    "canvaskit",
    "assets"
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

# Netlify 用 _headers / _redirects（Drop でも SPA ルーティングが効くように）
foreach ($file in @("_headers", "_redirects")) {
    $src = Join-Path $ProjectRoot "web\$file"
    $dst = Join-Path $outDir $file
    if (Test-Path $src) {
        Copy-Item $src $dst -Force
    }
}

# デプロイ確認用メタデータ
$version = Get-AppVersion
$meta = @{
    app        = "HomTune"
    version    = $version
    builtAt    = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    platform   = "web-preview"
    netlify    = $true
} | ConvertTo-Json -Depth 3
$meta | Set-Content -Path (Join-Path $outDir "deploy-meta.json") -Encoding UTF8

$readme = @"
HomTune Web デプロイ用フォルダ
==============================

バージョン: $version
ビルド日時: $(Get-Date -Format "yyyy-MM-dd HH:mm")

【Netlify Drop】
  1. https://app.netlify.com/drop を開く
  2. このフォルダ (build/web) 全体をドラッグ
     または dist/homtune-web-deploy.zip をドラッグ

【Netlify CLI】
  netlify deploy --prod --dir=build/web

【アップロードしてはいけないもの】
  x プロジェクト直下の web/  （ソースのみ → 白画面）
  x HomTune リポジトリ全体

【デプロイ後の確認】
  - https://あなたのURL/ が表示される
  - https://あなたのURL/main.dart.js が 404 でない
  - https://あなたのURL/deploy-meta.json でバージョン確認

【含まれる主な機能（Web プレビュー）】
  - オンボーディング / ホーム / 手入力登録
  - 家電詳細・メンテナンス UI
  - リモコン UI（API 連携なし・表示のみ）

【Web で無効】
  - スキャン / OCR / カメラ / 実 API キー連携
"@
$readme | Set-Content -Path (Join-Path $outDir "NETLIFY_DROP_README.txt") -Encoding UTF8

# zip（Netlify Drop 用）
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
$zipMb = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)

Write-Host ""
Write-Host "Build OK" -ForegroundColor Green
Write-Host "  version:      $version"
Write-Host "  main.dart.js: $mainJsMb MB"
Write-Host "  zip:          $zipMb MB"
Write-Host ""
Write-Host "Deploy to Netlify (choose one):" -ForegroundColor Yellow
Write-Host "  1. Drop folder:  $outDir"
Write-Host "  2. Drop zip:     $zipPath"
Write-Host "  3. CLI:          .\scripts\deploy_netlify.ps1"
Write-Host "  4. Local test:   flutter run -d chrome"
Write-Host ""
Write-Host "Do NOT upload the source web/ folder at repo root." -ForegroundColor Red
