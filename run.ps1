# HomTune Flutterアプリ実行スクリプト

Write-Host "HomTune Flutterアプリを起動します..." -ForegroundColor Cyan

# Flutterの確認
Write-Host "`nFlutterのバージョンを確認..." -ForegroundColor Yellow
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "エラー: Flutterがインストールされていません。" -ForegroundColor Red
    Write-Host "https://flutter.dev/docs/get-started/install/windows からインストールしてください。" -ForegroundColor Yellow
    exit 1
}

# 依存関係のインストール
Write-Host "`n依存関係をインストール..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "エラー: 依存関係のインストールに失敗しました。" -ForegroundColor Red
    exit 1
}

# 利用可能なデバイスを確認
Write-Host "`n利用可能なデバイスを確認..." -ForegroundColor Yellow
flutter devices

# エミュレータが起動しているか確認
$devices = flutter devices 2>&1 | Out-String
if ($devices -notmatch "emulator") {
    Write-Host "`n警告: Androidエミュレータが起動していません。" -ForegroundColor Red
    Write-Host "エミュレータを起動してください：" -ForegroundColor Yellow
    Write-Host "1. Android Studioを開く" -ForegroundColor Yellow
    Write-Host "2. Tools > Device Manager" -ForegroundColor Yellow
    Write-Host "3. エミュレータを選択して起動（▶ボタン）" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "または、コマンドラインから起動：" -ForegroundColor Yellow
    Write-Host "flutter emulators --launch Pixel_5" -ForegroundColor Cyan
    Write-Host ""
    $continue = Read-Host "エミュレータを起動してから続行しますか？ (y/n)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "実行をキャンセルしました。" -ForegroundColor Yellow
        exit 0
    }
    Write-Host "エミュレータが起動するまで待機中..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}

# アプリを実行
Write-Host "`nアプリを起動します..." -ForegroundColor Green
Write-Host ""

flutter run
