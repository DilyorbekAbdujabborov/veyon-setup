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

:: Ro'yxat serveri (ngrok static domen) va xona nomi
set "SERVER=https://true-ruling-vervet.ngrok-free.app"
set "ROOM=Sinf-1"

:: 2. O'qituvchi kaliti (public.pem) serverdan yuklab olinadi; server javob bermasa shu papkadagisi ishlatiladi
set "PEM=%~dp0public.pem"
echo [0/6] O'qituvchi kaliti serverdan yuklab olinmoqda...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $part = $env:PEM + '.part'; try { Invoke-WebRequest -UseBasicParsing -Uri ($env:SERVER + '/public.pem') -Headers @{ 'ngrok-skip-browser-warning' = '1' } -OutFile $part -TimeoutSec 15; if (-not (Select-String -Quiet -Path $part -Pattern 'BEGIN PUBLIC KEY')) { throw 'Serverdan kelgan fayl kalit emas' }; Move-Item -Force $part $env:PEM } catch { Write-Host $_.Exception.Message; Remove-Item -Force -ErrorAction SilentlyContinue $part; exit 1 }"
if errorlevel 1 (
    if exist "%PEM%" (
        echo [OGOHLANTIRISH] Serverdan olib bo'lmadi, shu papkadagi public.pem ishlatiladi.
    ) else (
        echo [XATO] public.pem serverdan ham, shu papkadan ham topilmadi!
        echo Server va ngrok ishlayotganini tekshiring.
        pause
        exit /b 1
    )
)

:: 3. Veyon o'rnatilganligini tekshirish: o'rnatilgan bo'lsa yuklab olish va o'rnatish o'tkazib yuboriladi
set "VEYON_DIR=%ProgramFiles%\Veyon"
set "VEYON_CLI=%VEYON_DIR%\veyon-cli.exe"
if exist "%VEYON_CLI%" (
    echo [1/6] Veyon allaqachon o'rnatilgan, o'rnatish o'tkazib yuborildi.
    goto :configure
)

:: 4. Veyon o'rnatuvchisi: avval shu papkadan qidiriladi, bo'lmasa internetdan shu yerga yuklab olinadi
set "VEYON_VER=4.11.4"
set "VEYON_URL=https://github.com/veyon/veyon/releases/download/v%VEYON_VER%/veyon-%VEYON_VER%.0-win64-setup.exe"
set "INSTALLER=%~dp0veyon-%VEYON_VER%.0-win64-setup.exe"
if exist "%INSTALLER%" (
    echo [1/6] O'rnatuvchi shu papkadan topildi, yuklab olish o'tkazib yuborildi.
) else (
    echo [1/6] Veyon rasmiy relizi yuklab olinmoqda...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -UseBasicParsing -Uri $env:VEYON_URL -OutFile ($env:INSTALLER + '.part'); Move-Item -Force ($env:INSTALLER + '.part') $env:INSTALLER } catch { Write-Host $_.Exception.Message; Remove-Item -Force -ErrorAction SilentlyContinue ($env:INSTALLER + '.part'); exit 1 }"
    if errorlevel 1 (
        echo [XATO] Internetdan yuklab olishda muammo bo'ldi. Ulanishni tekshiring.
        pause
        exit /b 1
    )
)

:: Shovqinsiz (Silent) faqat Service qismini o'rnatish
echo [2/6] Veyon Service rejimida o'rnatilmoqda...
start "" /wait "%INSTALLER%" /S /NoMaster
if errorlevel 1 (
    echo [XATO] Veyon o'rnatuvchisi xato bilan tugadi.
    pause
    exit /b 1
)

if not exist "%VEYON_CLI%" (
    echo [XATO] Veyon o'rnatilmadi yoki yo'l topilmadi: %VEYON_CLI%
    pause
    exit /b 1
)

:configure
:: 5. Autentifikatsiya kalitini import qilish (eski kalit bo'lsa avval o'chiriladi)
echo [3/6] O'qituvchi kaliti (public.pem) import qilinmoqda...
"%VEYON_CLI%" authkeys delete teacher/public >nul 2>&1
"%VEYON_CLI%" authkeys import teacher/public "%PEM%"
if errorlevel 1 (
    echo [XATO] Kalitni import qilib bo'lmadi.
    pause
    exit /b 1
)

:: 6. Kalit bilan kirish rejimini faollashtirish
echo [4/6] Kirish usuli 'Key file' rejimiga o'tkazilmoqda...
"%VEYON_CLI%" config set Authentication/Method 1
if errorlevel 1 (
    echo [XATO] Autentifikatsiya rejimini o'rnatib bo'lmadi.
    pause
    exit /b 1
)

:: 7. Windows Firewall portlarini ochish (Veyon: TCP 11100, 11200, 11300, 11400)
echo [5/6] Tarmoq xavfsizlik devori (Firewall) qoidalari qo'shilmoqda...
netsh advfirewall firewall delete rule name="Veyon Service" >nul 2>&1
netsh advfirewall firewall delete rule name="Veyon Ports" >nul 2>&1
netsh advfirewall firewall add rule name="Veyon Service" dir=in action=allow program="%VEYON_DIR%\veyon-service.exe" enable=yes profile=any >nul 2>&1
netsh advfirewall firewall add rule name="Veyon Ports" dir=in action=allow protocol=TCP localport=11100-11400 enable=yes profile=any >nul 2>&1

:: Xizmatni qayta ishga tushirish
"%VEYON_CLI%" service restart >nul 2>&1

:: 8. Kompyuterni o'qituvchi serverida ro'yxatdan o'tkazish (IP, nom, MAC)
echo [6/6] Kompyuter serverda ro'yxatdan o'tkazilmoqda (%SERVER%)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $c = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1; $body = @{ name = $env:COMPUTERNAME; ip = $c.IPv4Address[0].IPAddress; mac = $c.NetAdapter.MacAddress; room = $env:ROOM } | ConvertTo-Json; $r = Invoke-RestMethod -Method Post -Uri ($env:SERVER + '/register') -Headers @{ 'ngrok-skip-browser-warning' = '1' } -ContentType 'application/json' -Body $body -TimeoutSec 10; Write-Host ('  ' + $r.name + ' -> ' + $r.ip + ' (' + $r.room + ')') } catch { Write-Host $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo [OGOHLANTIRISH] Serverga ulanib bo'lmadi. Veyon sozlandi, lekin kompyuter o'qituvchida avtomatik chiqmaydi.
    echo SERVER manzilini tekshirib, skriptni qayta ishga tushiring.
)

echo.
echo ========================================================
echo  Muvaffaqiyatli yakunlandi! Kompyuter Masterga tayyor.
echo ========================================================
pause
