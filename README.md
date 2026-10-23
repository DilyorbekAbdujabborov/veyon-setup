# Veyon sinf o'rnatish

Shogird kompyuterlarga Veyon Service'ni o'rnatadi, o'qituvchi kalitini beradi, kompyuterni serverda ro'yxatga oladi.
O'qituvchi kompyuterida esa ro'yxatni xonalar bilan Veyon Master'ga avtomatik qo'shadi.

## Tarkib
- `server/` – Express serveri (ro'yxat, `public.pem`, skriptlar, bosh sahifa)
- `setup_client.bat` – shogird kompyuter (Windows)
- `setup_teacher.bat` / `setup_teacher.sh` – o'qituvchi kompyuter (Windows / Linux)

## Ishga tushirish
1. O'qituvchi kalitini chiqarib, shu papkaga `public.pem` nomi bilan qo'ying:
   `veyon-cli authkeys export teacher/public public.pem`
2. `ngrok.yml.example` dagi endpoint'ni `~/.config/ngrok/ngrok.yml` ga qo'shing.
3. Skriptlardagi `SERVER=` qiymatini o'z domeningizga almashtiring.
4. Server va tunnel:
   ```
   cd server && npm install
   npm start          # http://localhost:3100
   npm run tunnel     # ngrok start veyon
   ```

## O'rnatish (Administrator cmd / root)
Shogird (xona nomi ixtiyoriy):
```
curl -sLo "%TEMP%\v.bat" "https://DOMEN/c?room=Sinf-1" && "%TEMP%\v.bat"
```
O'qituvchi, Windows:
```
curl -sLo "%TEMP%\t.bat" https://DOMEN/t && "%TEMP%\t.bat"
```
O'qituvchi, Linux:
```
curl -sLo /tmp/t.sh https://DOMEN/t.sh && bash /tmp/t.sh
```

## Eslatmalar
- Server manzillari parolsiz ochiq: ngrok havolasini bilgan kishi ro'yxatni o'zgartira oladi.
- `setup_teacher.*` Veyon'dagi barcha xona va kompyuterlarni o'chirib, ro'yxatni serverdan qayta quradi.
- Master va shogirdlarda Veyon versiyasi bir xil bo'lishi kerak (skriptlarda `VEYON_VER`).
