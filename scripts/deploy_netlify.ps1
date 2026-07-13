# HomTune → Netlify 本番デプロイ（CLI）
# 前提: npm install -g netlify-cli && netlify login
param(
    [switch]$SkipBuild,
    [switch]$Draft
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

if (-not $SkipBuild) {
    & (Join-Path $PSScriptRoot "build_web_preview.ps1")
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$publishDir = Join-Path $ProjectRoot "build\web"
if (-not (Test-Path (Join-Path $publishDir "main.dart.js"))) {
    Write-Host "build/web is missing. Run build_web_preview.ps1 first." -ForegroundColor Red
    exit 1
}

$netlifyCmd = Get-Command netlify -ErrorAction SilentlyContinue
if (-not $netlifyCmd) {
    Write-Host "netlify-cli is not installed." -ForegroundColor Red
    Write-Host "  npm install -g netlify-cli"
    Write-Host "  netlify login"
    Write-Host ""
    Write-Host "Or use Netlify Drop with:" -ForegroundColor Yellow
    Write-Host "  $publishDir"
    Write-Host "  $(Join-Path $ProjectRoot 'dist\homtune-web-deploy.zip')"
    exit 1
}

$args = @("deploy", "--dir=$publishDir")
if (-not $Draft) {
    $args += "--prod"
}

Write-Host "Running: netlify $($args -join ' ')" -ForegroundColor Cyan
& netlify @args
