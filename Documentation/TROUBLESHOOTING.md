# Troubleshooting (คู่มือแก้ปัญหา)

ปัญหาที่พบได้บ่อย และวิธีแก้ตาม Project จริง

---

## Problem 1: Docker เปิดไม่ได้

**อาการ:** `docker --version` ไม่ตอบ หรือ Docker Desktop error
**สาเหตุ:** Virtualization ถูกปิด หรือติดตั้งไม่สมบูรณ์
**วิธีแก้:**
- เปิด Virtualization (VT-x) ใน BIOS/UEFI
- เปิด Windows Hyper-V / WSL2 (ติดตั้ง WSL: `wsl --install`)
- รีสตาร์ตแล้วเปิด Docker Desktop ใหม่

---

## Problem 2: Port ถูกใช้งานอยู่

**อาการ:** error `The port is already in use` ตอน `docker compose up`
**สาเหตุ:** พอร์ต 5001 / 3307 / 8090 มีโปรแกรมอื่นใช้อยู่
**วิธีแก้:**
- หาว่าใครใช้พอร์ต: `netstat -ano | findstr 5001`
- ปิดโปรแกรมนั้น หรือแก้ `ports:` ใน `docker-compose.yml`
  (แล้วต้องแก้ `apiPort` ใน `lib/services/api_config.dart` ให้ตรง)

> พอร์ตจริงของ Project: backend 5001→5000, mysql 3307→3306, phpmyadmin 8090→80

---

## Problem 3: Backend ติดต่อ Database ไม่ได้

**อาการ:** log backend แสดง `ECONNREFUSED` ไปที่ mysql
**วิธีแก้:**
- ตรวจว่า mysql healthy: `docker compose ps`
- Backend ต้องเชื่อมผ่าน host ชื่อ `mysql` พอร์ต `3306` (ใน docker network)
  ตาม `docker-compose.yml` — ไม่ใช่ `localhost`
- ตรวจ `.env` ว่า `MYSQL_ROOT_PASSWORD` ตรงกับที่ Compose ใช้

---

## Problem 4: MySQL Container ไม่ทำงาน

**อาการ:** `ebook-mysql` exit/restart ตลอด
**วิธีแก้:**
- ดู log: `docker compose logs mysql`
- ถ้า error รหัสผ่าน root ว่าง → ตรวจ `.env` มี `MYSQL_ROOT_PASSWORD`
- ถ้าเปลี่ยนรหัสผ่านแล้วต้องล้าง volume เก่า: `docker compose down -v`
  (คำสั่งนี้**ลบข้อมูลทั้งหมด**ในฐาน แล้วจะ re-init จาก `database.sql` ใหม่)

---

## Problem 5: Flutter ติดต่อ Backend ไม่ได้

**อาการ:** แอป error ติดต่อ API ไม่ได้
**วิธีแก้:**
- ตรวจ API ผ่านเว็บเบราว์เซอร์: `http://localhost:5001/api/health`
- ตรวจว่า `apiPort` ใน `lib/services/api_config.dart` = 5001
- ถ้าเป็น Android emulator ใช้ `10.0.2.2` ไม่ใช่ `localhost`

---

## Problem 6: localhost ใช้ไม่ได้จาก Android Emulator

**สาเหตุ:** `localhost` ภายใน emulator คือตัว emulator เอง ไม่ใช่เครื่อง server
**วิธีแก้:** ใช้ `10.0.2.2` (เป็น alias ไปยังเครื่อง host) ตามไฟล์จริง `api_config.dart`

---

## Problem 7: โทรศัพท์ Android จริงต่อ Backend ไม่ได้

**สาเหตุ:** โทรศัพท์เข้าถึงเครื่อง server ผ่าน IP จริง ไม่ใช่ localhost
**วิธีแก้:**
- หา IP ของเครื่อง server: `ipconfig` (เช่น 192.168.1.100)
- เปลี่ยน `_host` ใน `lib/services/api_config.dart` เป็น IP นั้นแล้ว rebuild
- โทรศัพท์กับเครื่อง server ต้องอยู่บน network เดียวกัน
- เปิด firewall port 5001 (Windows Firewall) ตามหัวข้อที่เกี่ยวข้อง

---

## Problem 8: ภาษาไทย/ลาวแสดงเป็นภาษาต่างดาว (mojibake)

**สาเหตุ:** ฐาน/การเชื่อมต่อไม่ใช้ utf8mb4
**วิธีแก้:** Project จัดการแล้วโดย:
- `database.sql` มี `SET NAMES utf8mb4` และ `CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
- `docker-compose.yml` mysql ใช้ `--character-set-server=utf8mb4` และ
  `--skip-character-set-client-handshake`
- `config/db.js` ใช้ `charset: 'utf8mb4'`
ถ้ายังเพี้ยน ให้ re-import `database.sql` ใหม่ (ล้าง volume ก่อน)

---

## Problem 9: .env ไม่ถูกโหลด

**สาเหตุ:** ไฟล์ `.env` ไม่มี หรือค่าถูกแทนเป็นสตริงว่าง
**วิธีแก้:**
- ตรวจว่าไฟล์ `.env` อยู่ที่ root ของ Project
- เติม `MYSQL_ROOT_PASSWORD` และ `JWT_SECRET`
- หลังแก้ `.env` ต้องบังคับสร้าง container ใหม่:
  `docker compose up -d --force-recreate`

---

## Problem 10: JWT / Authentication Error

**อาการ:** ทุก API คืน 401 หลัง login สำเร็จ
**สาเหตุ:** `JWT_SECRET` ไม่ตรง (เช่น env ค้างค่าเก่า)
**วิธีแก้:**
- ตรวจ `.env` ว่ามี `JWT_SECRET`
- หลังแก้ ต้อง recreate container: `docker compose up -d --force-recreate backend`
- server.js จะหยุดทันทีถ้าไม่มี JWT_SECRET (ออกแบบไว้เพื่อความปลอดภัย)

---

## Problem 11: Upload File ไม่ทำงาน

**สาเหตุ:** ขนาดเกิน 100MB, นามสกุลไม่รองรับ, หรือไม่ได้ login
**วิธีแก้:**
- รองรับเฉพาะ jpg, jpeg, png, webp, gif, pdf และสูงสุด 100MB (ไฟล์จริง `middleware/upload.js`)
- ต้อง login ก่อน (requireAuth บังคับที่ `/api/upload`)
- ไฟล์ถูกเก็บใน volume `backend-uploads` อยู่ที่ `/app/uploads` ใน container

---

## Problem 12: Flutter dependency error

**สาเหตุ:** เวอร์ชัน Dart/Flutter ต่ำ หรือ pub get ไม่ผ่าน
**วิธีแก้:**
- ต้องใช้ Flutter 3.41.0+ (Dart 3.10+) ตาม `GEMINI.md`
- รัน `flutter pub get` ใหม่
- ถ้ายัง error: `flutter clean` แล้ว `flutter pub get`

---

## Problem 13: Android SDK / Java version ไม่ตรง

**สาเหตุ:** Java ไม่ใช่ 17 หรือ SDK ไมครบ
**วิธีแก้:**
- ติดตั้ง Java 17 (ไฟล์จริง `android/app/build.gradle.kts` ระบุ Java 17)
- ติดตั้ง Android SDK ผ่าน Android Studio
- ตรวจ: `flutter doctor`

---

## Problem 14: Docker container start แล้วหยุดทันที

**สาเหตุ:** ค่าผิดใน .env / DB ไม่พร้อม / port ขัดกัน
**วิธีแก้:**
- ดู log: `docker compose logs <service>`
- ตรวจ order: backend/phpmyadmin มี `depends_on` ว่า mysql ต้อง healthy ก่อน
- หลังแก้ env: `docker compose up -d --force-recreate`

---

## Problem 15: Database ไม่มีข้อมูล

**สาเหตุ:** volume ถูกสร้างก่อนที่ `database.sql` จะถูก import
**วิธีแก้:**
- `database.sql` ถูก import ครั้งเดียวตอน volume ว่าง
- ต้องล้าง volume แล้วเริ่มใหม่: `docker compose down -v && docker compose up -d --build`
  (คำสั่งนี้ลบข้อมูลทั้งหมดแล้วสร้างใหม่พร้อม seed)

---

## Problem 16: เปิดแอปแล้วหน้า Login ผิดฝั่ง

**สาเหตุ:** ใช้ platform ผิด (Admin บนแอป, User บน Web)
**วิธีแก้:**
- Admin/Employee ต้องเข้า Web: `flutter run -d chrome`
- User/Member ต้องเข้า Flutter App: `flutter run -d windows`
- ระบบจะแจ้งว่า "ใช้ได้ผ่าน Web เท่านั้น" หรือ "ผ่านแอปเท่านั้น"