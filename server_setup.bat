@echo off
setlocal
cd /d "%~dp0"
:: Serverni bir marta tayyorlaydi: paketlar, server\.env (PUBLIC_URL) va o'qituvchi kaliti (public.pem).
:: Ishga tushirish: server_setup.bat   yoki   server_setup.bat https://domen.ngrok-free.app

:: 1. Node.js 20.12+ (.env ni o'qish uchun)
where node >nul 2>&1
if errorlevel 1 (
    echo [XATO] Node.js topilmadi. https://nodejs.org dan o'rnating, 20.12 yoki yangi.
    pause
    exit /b 1
)
node -e "const [a,b]=process.versions.node.split('.').map(Number); process.exit(a>20||(a===20&&b>=12)?0:1)"
if errorlevel 1 (
    echo [XATO] Node.js 20.12 yoki yangi kerak.
    node -v
    pause
    exit /b 1
)

:: 2. Paketlar
echo [1/4] Paketlar o'rnatilmoqda...
pushd server
call npm install --no-audit --no-fund --silent
if errorlevel 1 (
    popd
    echo [XATO] npm install muvaffaqiyatsiz tugadi.
    pause
    exit /b 1
)
popd

:: 3. server\.env va PUBLIC_URL
echo [2/4] Sozlamalar ^(server\.env^)...
if not exist "server\.env" copy /y "server\.env.example" "server\.env" >nul
set "CURRENT="
for /f "usebackq tokens=1,* delims== eol=#" %%A in ("server\.env") do if /i "%%A"=="PUBLIC_URL" set "CURRENT=%%B"

set "URL=%~1"
if not defined URL (
    if defined CURRENT if /i not "%CURRENT%"=="https://your-domain.ngrok-free.app" (
        set "URL=%CURRENT%"
        echo   PUBLIC_URL o'zgarmadi.
    )
)
if not defined URL set /p "URL=  Public URL (masalan https://nom.ngrok-free.app): "

if "%URL:~-1%"=="/" set "URL=%URL:~0,-1%"
powershell -NoProfile -Command "if ($env:URL -notmatch '^https?://[A-Za-z0-9.-]+(:\d+)?$') { exit 1 }"
if errorlevel 1 (
    echo [XATO] PUBLIC_URL noto'g'ri: %URL%
    echo https://domen.ngrok-free.app ko'rinishida bo'lsin.
    pause
    exit /b 1
)
powershell -NoProfile -Command "(Get-Content 'server\.env') -replace '^PUBLIC_URL=.*', ('PUBLIC_URL=' + $env:URL) | Set-Content -Encoding ascii 'server\.env'"
echo   PUBLIC_URL=%URL%

:: 4. O'qituvchi kaliti
echo [3/4] O'qituvchi kaliti ^(public.pem^)...
if exist "public.pem" (
    echo   public.pem bor.
) else (
    set "EXPORTED="
    if exist "%ProgramFiles%\Veyon\veyon-cli.exe" (
        "%ProgramFiles%\Veyon\veyon-cli.exe" authkeys export teacher/public "%~dp0public.pem" >nul 2>&1
        if not errorlevel 1 set "EXPORTED=1"
    )
    if defined EXPORTED (
        echo   Veyon'dan chiqarib olindi: public.pem
    ) else (
        echo   [OGOHLANTIRISH] public.pem yo'q. Shogirdlar kalit ola olmaydi.
        echo   Yaratish: veyon-cli authkeys create teacher
        echo   Chiqarish: veyon-cli authkeys export teacher/public public.pem
    )
)

:: 5. ngrok
echo [4/4] ngrok...
where ngrok >nul 2>&1
if errorlevel 1 (
    echo   [OGOHLANTIRISH] ngrok topilmadi: https://ngrok.com/download
    echo   O'rnatgach: ngrok config add-authtoken TOKEN
) else (
    echo   ngrok bor.
)

echo.
echo Tayyor. Ishga tushirish: start.bat
pause
