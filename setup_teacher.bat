@echo off
setlocal

:: 1. Administrator huquqlarini tekshirish
net session >nul 2>&1
if errorlevel 1 (
    echo [XATO] Iltimos, ushbu skriptni sichqonchaning o'ng tugmasi bilan
    echo "Run as administrator" ^(Administrator nomidan^) ishga tushiring!
    pause
    exit /b 1
)

cd /d "%~dp0"

:: Ro'yxat serveri (ngrok static domen). Faqat bitta xonani olish uchun ROOM ni to'ldiring, bo'sh bo'lsa hammasi olinadi
set "SERVER=https://true-ruling-vervet.ngrok-free.app"
set "ROOM="

set "VEYON_CLI=%ProgramFiles%\Veyon\veyon-cli.exe"
if not exist "%VEYON_CLI%" (
    echo [XATO] Veyon topilmadi: %VEYON_CLI%
    echo Avval o'qituvchi kompyuteriga Veyon Master o'rnating.
    pause
    exit /b 1
)

:: 2. Kompyuterlar ro'yxatini serverdan yuklab olish
set "CSV=%TEMP%\veyon-computers.csv"
echo [1/3] Kompyuterlar ro'yxati serverdan olinmoqda (%SERVER%)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $uri = $env:SERVER + '/computers.csv'; if ($env:ROOM) { $uri += '?room=' + [uri]::EscapeDataString($env:ROOM) }; Invoke-WebRequest -UseBasicParsing -Uri $uri -Headers @{ 'ngrok-skip-browser-warning' = '1' } -OutFile $env:CSV -TimeoutSec 15; $n = @(Get-Content $env:CSV | Where-Object { $_.Trim() }).Count; Write-Host ('  ' + $n + ' ta kompyuter topildi'); if ($n -eq 0) { exit 2 } } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 2 (
    echo [XATO] Serverda hali birorta kompyuter ro'yxatdan o'tmagan.
    pause
    exit /b 1
)
if errorlevel 1 (
    echo [XATO] Serverga ulanib bo'lmadi. Server va ngrok ishlayotganini tekshiring.
    pause
    exit /b 1
)

:: 3. Eski ro'yxatni tozalab, xonalar va kompyuterlarni import qilish (xonalar avtomatik yaratiladi)
echo [2/3] Eski xona va kompyuterlar tozalanmoqda...
"%VEYON_CLI%" networkobjects clear

echo [3/3] Xonalar yaratilib, kompyuterlar qo'shilmoqda...
"%VEYON_CLI%" networkobjects import "%CSV%" format "%%location%%;%%name%%;%%host%%;%%mac%%"
if errorlevel 1 (
    echo [XATO] Kompyuterlarni import qilib bo'lmadi.
    pause
    exit /b 1
)

echo.
"%VEYON_CLI%" networkobjects list

echo.
echo ========================================================
echo  Tayyor! Veyon Master'ni qayta oching.
echo ========================================================
pause
