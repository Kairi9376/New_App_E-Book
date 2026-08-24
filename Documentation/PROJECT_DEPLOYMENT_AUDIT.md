# Project Deployment Audit (สำหรับ Developer/Admin)

เอกสารนี้เป็นรายงานการตรวจสอบ Project จริง ก่อนส่งให้ลูกค้า
รวมถึงปัญหาที่ต้องแก้และความเสี่ยงต่าง ๆ

---

## 1. Project Architecture

```
Flutter App (flutter_application_1)
   |  HTTP API : http://localhost:5001/api  (host 5001 -> container 5000)
   v
Node.js + Express Backend (Docker container: ebook-backend)
   |  mysql2/promise pool -> host "mysql" : 3306 (Docker network "ebook-network")
   v
MySQL 8.0 (Docker container: ebook-mysql) + phpMyAdmin (ebook-phpmyadmin)
```

- ฝั่ง Admin/Employee ใช้ **Web** (`flutter run -d chrome`)
- ฝั่ง User/Member ใช้ **Flutter App** (`flutter run -d windows` หรือ Android)

---

## 2. Technology Stack

| ส่วน | เทคโนโลยี | เวอร์ชัน/เงื่อนไข |
| ------ | ------ | ------ |
| Frontend | Flutter / Dart | pubspec.yaml: sdk '>=3.7.0 <4.0.0', flutter '>=3.29.0' (GEMINI.md บังคับ 3.41.0+) |
| Backend | Node.js + Express | Express ^4.19.2; Docker image node:20-alpine |
| Database | MySQL | image mysql:8.0, charset utf8mb4, collation utf8mb4_unicode_ci |
| DB UI | phpMyAdmin | image phpmyadmin:latest |
| Docker | Docker Compose | ใช้ `docker compose` (ไม่มีใน Windows ต้องติดตั้ง Docker Desktop) |

---

## 3. Backend Dependencies (จาก Backend/package.json)

- express ^4.19.2
- mysql2 ^3.9.7
- bcryptjs ^2.4.3
- jsonwebtoken ^9.0.2
- cors ^2.8.5
- dotenv ^16.4.5
- multer ^2.2.0
- dev: nodemon ^3.1.0

---

## 4. Ports (จริงจาก docker-compose.yml)

| Service | Host Port | Container Port | ใช้ทำอะไร |
| ------ | :---: | :---: | ------ |
| backend | 5001 | 5000 | REST API (Flutter ต่อ 5001) |
| mysql | 3307 | 3306 | ฐานข้อมูล |
| phpmyadmin | 8090 | 80 | จัดการฐานผ่านเว็บ |

> ความต่าง HOST vs CONTAINER: host port คือพอร์ตที่เครื่องลูกค้าใช้เข้าถึง
> container port คือพอร์ตภายใน container. ตัวอย่าง `5001:5000`
> = เครื่องลูกค้าใช้ 5001, container ฟัง 5000.

Flutter ใช้พอร์ต 5001 (`ApiConfig.apiPort` ใน `lib/services/api_config.dart`)

---

## 5. Docker Services

| Service | Image | container_name | depends_on |
| ------ | ------ | ------ | ------ |
| mysql | mysql:8.0 | ebook-mysql | - |
| backend | build ./Backend | ebook-backend | mysql healthy |
| phpmyadmin | phpmyadmin:latest | ebook-phpmyadmin | mysql healthy |

- Network: `ebook-network` (bridge)
- Volumes: `mysql-data` (/var/lib/mysql), `backend-uploads` (/app/uploads)
- MySQL init: `Backend/database.sql` ถูก import ครั้งเดียวตอน volume ว่าง
- Healthcheck: mysql (mysqladmin ping) และ backend (GET /api/health)

---

## 6. Database

- ชื่อฐาน: `ebook_db`
- วิธีสร้าง: ผ่าน Docker init จาก `Backend/database.sql` (ครั้งเดียวตอน volume ว่าง)
- Charset: `utf8mb4`, Collation: `utf8mb4_unicode_ci`
- 13 ตาราง: users, kyc_verifications, authors, categories, books,
  book_categories, packages, subscriptions, bookmarks, reading_history,
  downloads, notifications, audit_logs
- Seed: 4 users, 4 authors, 5 categories, 3 packages, 5 books,
  subscriptions, kyc, bookmarks, history, downloads, notifications

---

## 7. Environment Variables

| Variable | ใช้ทำอะไร | ที่มาค่า | จำเป็น |
| ------ | ------ | ------ | :---: |
| MYSQL_ROOT_PASSWORD | รหัส root MySQL | ไฟล์ `.env` root | ใช่ |
| JWT_SECRET | sign JWT token | ไฟล์ `.env` root | ใช่ |
| PORT | พอร์ต backend (ใน container = 5000) | `.env` / compose | ใช่ |
| PUBLIC_BASE_URL | URL พื้นฐานสำหรับ URL ไฟล์สาธารณะ (http://localhost:5001) | `.env` | ใช่ |

Backend อ่าน env เพิ่มเติม (หากรันตรง ไม่ผ่าน Docker): DB_HOST, DB_USER, DB_PASSWORD,
DB_NAME, DB_PORT (ค่าเริ่มต้นใน `config/db.js`) — `.env.example` ของ Backend มีตัวอย่าง

> ค่าลับจริงไม่แสดงในเอกสารนี้ ต้องตั้งค่าเองใน `.env`

---

## 8. Flutter Configuration

- Entry point: `lib/main.dart`
- API URL: `lib/services/api_config.dart`
  - `apiPort = 5001`
  - `_host`: Android (ไม่ใช่ web) → `10.0.2.2`, อื่น ๆ → `localhost`
  - `baseUrl` = `http://<host>:5001/api`
- dependencies หลัก: http, url_launcher, flutter_svg, shared_preferences,
  file_picker, pdfrx (ดู pubspec.yaml)
- Android: namespace com.example.flutter_application_1, Java 17,
  gradle 9.1.0, INTERNET permission เฉพาะ debug manifest
- Web: `flutter build web` รองรับ (index.html ใน web/)
- บทบาท/Platform: `lib/services/auth_gate.dart`

---

## 9. Backend Configuration

- Entry point: `server.js`
- `get('/')` แสดงสถานะ, `get('/api/health')` → `{status:"OK"}` (ใช้ใน healthcheck)
- Express middleware: cors (เปิดทั้งหมด), express.json, urlencoded
- Static: `/uploads` ชี้ที่ `uploads/`
- `/api/upload` มี `requireAuth` (ต้อง login)
- Routes: /api/auth, /api/users, /api/kyc, /api/authors, /api/categories,
  /api/books, /api/packages, /api/subscriptions, /api/bookmarks, /api/history,
  /api/downloads, /api/notifications, /api/audit-logs
- Auth: bcryptjs + jsonwebtoken (JWT อายุ 7 วัน), fallback secret ถูกลบแล้ว
  (ถ้าไม่มี JWT_SECRET server.js จะหยุด)

---

## 10. Security Issues (ต้องแก้ก่อนส่งลูกค้า)

- [ ] `.env` มีค่าลับจริง (MYSQL_ROOT_PASSWORD, JWT_SECRET) — **ต้องเปลี่ยน** ก่อน Copy ลง USB
- [ ] CORS เปิดกว้างทั้งหมด (`app.use(cors())`) — ถ้าเจอ Production ต้องจำกัด origin
- [ ] บัญชี seed เป็นที่รู้จักสาธารณะ (admin@gmail.com/admin123456 ฯลฯ) — ให้เปลี่ยนรหัส
- [ ] Backend ใช้ MySQL `root` — ควรสร้าง user เฉพาะสิทธิ์น้อยกว่า
- [ ] รหัสผ่าน root MySQL ใช้ทั้ง 3 service — เก็บเป็นความลับ
- [ ] ยังเป็น Development configuration (กลับไปที่หัวข้อ Known Issues) — ยังไม่ Production-ready

---

## 11. Known Issues

- ชื่อ package ยังเป็นค่าเริ่มต้น `com.example.flutter_application_1` ยังไม่ได้เปลี่ยน
- ข้อความในโค้ด log บางส่วนอ้างถึง XAMPP (ทั้งที่ใช้ Docker)
- มี `GEMINI.md` ภายใน repository ที่เป็นบันทึกการพัฒนา (ไม่ควรส่งให้ลูกค้า)
- port 5000 host ใช้ไม่ได้บน macOS (AirPlay) → ใช้ 5001 แทน
- เปลี่ยนรหัสผ่าน MySQL หลัง up ครั้งแรก ต้อง `docker compose down -v` (ลบข้อมูล)

---

## 12. Deployment Risks

- ลูกค้าต้องมี Flutter 3.41+ / Docker Desktop มิฉะนั้น pub get / compose พัง
- USB ต้องไม่รวม `.flutter-plugins`, `build/`, `node_modules/` (ที่อยู่เครื่องเดิม)
- ถ้าส่ง `.env` ที่มีค่าลับเก่า = เสี่ยงความปลอดภัย
- ต้องเปิด port 5001 ใน Windows Firewall ถ้าใช้ Android จริง
- โมบายจริงต้องแก้ `api_config.dart` ให้ใช้ IP ของเครื่อง server

---

## 13. สิ่งที่ต้องเตรียมก่อนส่งให้ลูกค้า (Checklist)

- [ ] เปลี่ยน MYSQL_ROOT_PASSWORD และ JWT_SECRET ใน `.env`
- [ ] รัน `docker compose up -d --build` และทดสอบให้ผ่านก่อน
- [ ] ทดสอบ `flutter analyze` และ `flutter pub get` ผ่าน
- [ ] ลบโฟลเดอร์ build/ และ node_modules/ ออกจาก USB (ถ้ามี)
- [ ] ตรวจว่าไม่รวม `.env` จริงในไฟล์ที่แชร์ (มีเฉพาะ .env.example)
- [ ] เตรียม Documentation ครบ (INSTALLATION_GUIDE, QUICK_START, TROUBLESHOOTING, SYSTEM_REQUIREMENTS)
- [ ] ทดสอบ install ใหม่บนเครื่องสะอาดตาม INSTALLATION_GUIDE ก่อนส่งจริง