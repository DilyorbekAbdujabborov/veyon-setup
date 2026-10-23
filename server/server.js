// Veyon ro'yxatga olish serveri:
//   POST /register        - shogird kompyuter o'zini ro'yxatdan o'tkazadi
//   GET  /computers       - barcha kompyuterlar (JSON)
//   GET  /computers.csv   - veyon-cli networkobjects import uchun CSV (location;name;host;mac)
//   DELETE /computers/:name - kompyuterni ro'yxatdan o'chirish
//   GET  /public.pem      - o'qituvchi ochiq kaliti (setup_client.bat yuklab oladi)
//   GET  /                - bosh sahifa: o'rnatish buyruqlari va kompyuterlar ro'yxati
//   GET  /c?room=Sinf-2   - setup_client.bat ning eng yangi versiyasi (room berilsa ROOM almashtiriladi)
//   GET  /t?room=Sinf-2   - setup_teacher.bat ning eng yangi versiyasi
//   GET  /t.sh            - setup_teacher.sh (Linux o'qituvchi uchun)
const express = require('express');
const fs = require('fs');
const net = require('net');
const path = require('path');

const PORT = process.env.PORT || 3100;
const DEFAULT_ROOM = process.env.DEFAULT_ROOM || 'Sinf-1';
const DATA_FILE = path.join(__dirname, 'computers.json');
const PUBLIC_KEY_FILE = process.env.PUBLIC_KEY_FILE || path.join(__dirname, '..', 'public.pem');

let computers = {};
try {
  computers = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
} catch {
  computers = {};
}

// Yarim yozilgan fayl qolmasligi uchun avval vaqtinchalik faylga yoziladi
function save() {
  const tmp = DATA_FILE + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(computers, null, 2));
  fs.renameSync(tmp, DATA_FILE);
}

// CSV ajratuvchisi va qo'shtirnoqlar import formatini buzmasligi uchun tozalanadi
function clean(value) {
  return String(value || '').replace(/[;"\r\n]/g, '').trim();
}

function remoteIp(req) {
  return (req.socket.remoteAddress || '').replace(/^::ffff:/, '');
}

function isLoopback(ip) {
  return ip === '::1' || ip.startsWith('127.');
}

const app = express();
app.use(express.json({ limit: '10kb' }));

app.post('/register', (req, res) => {
  const body = req.body || {};
  const name = String(body.name || '').trim().toUpperCase();
  if (!/^[A-Z0-9_.-]{1,63}$/.test(name)) return res.status(400).json({ error: 'name noto\'g\'ri' });

  // ngrok orqali ulanish manzili tunnelniki bo'ladi, shuning uchun kompyuter yuborgan LAN IP ishlatiladi
  const ip = clean(body.ip) || remoteIp(req);
  if (!net.isIP(ip) || isLoopback(ip)) return res.status(400).json({ error: 'ip aniqlanmadi' });
  const mac = clean(body.mac).replace(/-/g, ':').toUpperCase();
  if (mac && !/^([0-9A-F]{2}:){5}[0-9A-F]{2}$/.test(mac)) return res.status(400).json({ error: 'mac noto\'g\'ri' });
  const room = clean(body.room).slice(0, 64) || DEFAULT_ROOM;

  computers[name] = { name, ip, mac, room, updatedAt: new Date().toISOString() };
  save();
  console.log(`[register] ${name} ${ip} ${mac} -> ${room}`);
  res.json(computers[name]);
});

function filtered(req) {
  const list = Object.values(computers);
  return req.query.room ? list.filter((c) => c.room === req.query.room) : list;
}

app.get('/computers', (req, res) => {
  res.json(filtered(req));
});

app.get('/computers.csv', (req, res) => {
  const csv = filtered(req)
    .map((c) => [c.room, c.name, c.ip, c.mac].join(';'))
    .join('\r\n');
  res.type('text/csv').send(csv ? csv + '\r\n' : '');
});

app.delete('/computers/:name', (req, res) => {
  const name = req.params.name.toUpperCase();
  if (!computers[name]) return res.status(404).json({ error: 'topilmadi' });
  delete computers[name];
  save();
  res.json({ ok: true });
});

app.get('/public.pem', (req, res) => {
  if (!fs.existsSync(PUBLIC_KEY_FILE)) return res.status(404).json({ error: 'public.pem topilmadi' });
  res.type('application/x-pem-file').sendFile(path.resolve(PUBLIC_KEY_FILE));
});

// Bosh sahifa (public/index.html)
app.use(express.static(path.join(__dirname, 'public')));

// Bat fayllar har so'rovda diskdan o'qiladi, shuning uchun doim eng yangi versiya beriladi
const SCRIPTS_DIR = path.join(__dirname, '..');

function sendScript(file) {
  return (req, res) => {
    let text;
    try {
      text = fs.readFileSync(path.join(SCRIPTS_DIR, file), 'utf8');
    } catch {
      return res.status(404).send('topilmadi');
    }
    const room = clean(req.query.room).replace(/[%^&|<>!]/g, '');
    if (room) text = text.replace(/^set "ROOM=.*"\r?$/m, `set "ROOM=${room}"\r`);
    res.type('application/x-bat').attachment(file).send(text);
  };
}

app.get(['/c', '/client.bat'], sendScript('setup_client.bat'));
app.get(['/t', '/teacher.bat'], sendScript('setup_teacher.bat'));
app.get(['/t.sh', '/teacher.sh'], sendScript('setup_teacher.sh'));

// Noto'g'ri JSON va boshqa kutilmagan xatolar server to'xtashiga olib kelmasin
app.use((err, req, res, next) => {
  res.status(err.status || 500).json({ error: err.status ? 'noto\'g\'ri so\'rov' : 'server xatosi' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Veyon ro'yxat serveri ishga tushdi: http://0.0.0.0:${PORT}`);
});
