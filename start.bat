@echo off
setlocal
cd /d "%~dp0server"
:: Serverni va ngrok tunnelini birga ishga tushiradi. Oynani yopsangiz yoki Ctrl+C bossangiz ikkalasi to'xtaydi.

if not exist ".env" (
    echo [XATO] server\.env yo'q. Avval server_setup.bat ni ishga tushiring.
    pause
    exit /b 1
)

set "PUBLIC_URL="
set "PORT=3100"
for /f "usebackq tokens=1,* delims== eol=#" %%A in (".env") do (
    if /i "%%A"=="PUBLIC_URL" set "PUBLIC_URL=%%B"
    if /i "%%A"=="PORT" set "PORT=%%B"
)
if not defined PUBLIC_URL (
    echo [XATO] server\.env ichida PUBLIC_URL yozilmagan.
    pause
    exit /b 1
)
set "DOMAIN=%PUBLIC_URL:*://=%"

where ngrok >nul 2>&1
if errorlevel 1 (
    echo [XATO] ngrok topilmadi: https://ngrok.com/download
    pause
    exit /b 1
)

start "" /b node server.js

echo Tunnel: %PUBLIC_URL% -^> localhost:%PORT%
ngrok http %PORT% --url=%DOMAIN% --log=stdout

