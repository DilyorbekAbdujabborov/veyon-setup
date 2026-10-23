# Veyon sinf o'rnatish

Shogird kompyuterlarga Veyon'ni **bitta buyruq** bilan o'rnatadi va ro'yxatga oladi.
O'qituvchi kompyuterida esa ro'yxatni xonalar bilan Veyon Master'ga **avtomatik** qo'shadi.

```
shogird PC  --(1 buyruq)-->  server (Express + ngrok)  <--(1 buyruq)--  o'qituvchi PC
 o'rnatadi, kalit oladi,      kompyuterlar ro'yxati,                    ro'yxatni olib, xonalarni
 IP ni serverga yuboradi      public.pem, skriptlar, sahifa             yaratib Master'ga qo'shadi
```

## 1. Server (bir marta)

Kerak: Node.js 20.12+, [ngrok](https://ngrok.com/download) (+ static domen), Veyon (o'qituvchi kaliti uchun).

```
./server_setup.sh https://SIZNING-DOMEN.ngrok-free.app
./start.sh
```

- `server_setup.sh` paketlarni o'rnatadi, `server/.env` ga **PUBLIC_URL** ni yozadi va `public.pem` ni tayyorlaydi.
- `start.sh` serverni (port 3100) va ngrok tunnelini birga ishga tushiradi. `Ctrl+C` ikkalasini to'xtatadi.
- Sahifa: `PUBLIC_URL` manzilining o'zi. Unda tayyor buyruqlar va ro'yxatdagi kompyuterlar chiqadi.

### `server/.env`
| O'zgaruvchi | Ma'nosi |
|---|---|
| `PUBLIC_URL` | **Majburiy.** Tashqaridan ko'rinadigan manzil (ngrok domeni), oxirida `/` siz |
| `PORT` | Ixtiyoriy, standart `3100` |
| `DEFAULT_ROOM` | Ixtiyoriy, xona berilmasa shu ishlatiladi (`Sinf-1`) |
| `PUBLIC_KEY_FILE` | Ixtiyoriy, standart `../public.pem` |

Server skriptlarni yuborayotganda ichidagi `SERVER=` qiymatini `PUBLIC_URL` bilan o'zi almashtiradi, skriptlarni qo'lda tahrirlash shart emas.

## 2. Shogird kompyuter

**Administrator** sifatida ochilgan `cmd` da (xona nomini o'zgartirish mumkin):
```
curl -sLo "%TEMP%\v.bat" "https://DOMEN/c?room=Sinf-1" && "%TEMP%\v.bat"
```
Skript: Veyon o'rnatilgan bo'lsa qayta o'rnatmaydi, kalitni serverdan oladi, firewall'ni sozlaydi, nom va IP ni serverga yuboradi.

## 3. O'qituvchi kompyuter

Windows (Administrator `cmd`):
```
curl -sLo "%TEMP%\t.bat" https://DOMEN/t && "%TEMP%\t.bat"
```
Linux:
```
curl -sLo /tmp/t.sh https://DOMEN/t.sh && bash /tmp/t.sh
```
Keyin Veyon Master'ni qayta oching, xonalar va kompyuterlar tayyor bo'ladi.

## Server manzillari
| Manzil | Vazifasi |
|---|---|
| `/` | Bosh sahifa |
| `/c?room=X` | `setup_client.bat` |
| `/t`, `/t.sh` | `setup_teacher.bat`, `setup_teacher.sh` |
| `/public.pem` | O'qituvchi kaliti |
| `POST /register` | Kompyuterni ro'yxatga olish |
| `/computers`, `/computers.csv` | Ro'yxat (JSON, CSV) |
| `DELETE /computers/NOM` | Ro'yxatdan o'chirish |

## Eslatmalar
- Server parolsiz: ngrok havolasini bilgan kishi ro'yxatni o'zgartira oladi.
- `setup_teacher.*` Master'dagi barcha xona va kompyuterlarni o'chirib, ro'yxatni serverdan qayta quradi.
- Veyon versiyasi hamma kompyuterlarda bir xil bo'lishi kerak (`VEYON_VER` skriptda).
- `public.pem` repoga kirmaydi. Uni `veyon-cli authkeys export teacher/public public.pem` bilan chiqaring (`server_setup.sh` buni o'zi qiladi).
