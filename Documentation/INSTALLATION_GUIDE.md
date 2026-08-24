# คู่มือติดตั้งและรัน Project E-Book (สำหรับลูกค้า)

> เวอร์ชัน: 1.0.0 | ระบบหลัก: Windows (PowerShell / CMD) | ผู้อ่าน: ผู้ไม่เป็น Developer

คู่มือนี้เขียนจากการอ่าน source code และ config จริง ได้แก่ `docker-compose.yml`,
`.env.example`, `Backend/server.js`, `Backend/config/db.js`, `Backend/Dockerfile`,
`Backend/package.json`, `Backend/database.sql`, `flutter_application_1/pubspec.yaml`,
`lib/main.dart`, `lib/services/api_config.dart`, และ `android/*`.

---

## 0. ระบบนี้คืออะไร

แพลตฟอร์มอ่านและจัดการหนังสือ E-Book (PDF):

```
Flutter App (ผู้ใช้)
   |  HTTP API : พอร์ต 5001
   v
Node.js + Express Backend (Docker)
   |  เชื่อมผ่าน Docker Network (host: mysql)
   v
MySQL 8.0 Database (Docker)
```

บทบาท: Admin/Employee เข้าได้บน **Web** (`flutter run -d chrome`).
User/Member เข้าได้บน **Flutter App** (`flutter run -d windows` หรือบน Android `flutter run`).

---

## 1. STEP 1 - เตรียมเครื่อง

- ตรวจ: `ver` ควรเป็น Windows 10/11 64-bit
- ตรวจ RAM/ที่ว่าง: `wmic memorychip get capacity` และ `wmic logicaldisk get size,freespace`
- ควรมี RAM 8GB+ และที่ว่าง 30GB+

---

## 2. STEP 2 - ติดตั้ง Flutter / Dart SDK

เงื่อนไขจริงใน `pubspec.yaml`: `sdk '>=3.7.0 <4.0.0'`, `flutter '>=3.29.0'`
แต่ไฟล์ `GEMINI.md` บังคับว่า ต้องใช้ **Flutter 3.41.0+ (Dart 3.10+)** เพราะแพ็ก `pdfrx`.

- ดาวน์โหลด Dart SDK จาก `https://dart.dev/` แล้วเพิ่ม `bin` ใน PATH
- ตรวจ: `flutter --version`

---

## 3. STEP 3 - Visual Studio (สำหรับ Windows Desktop)

ต้องมี Visual Studio 2022+ และ workload **"Desktop development with C++"**.
ตรวจ: `flutter doctor`

---

## 4. STEP 4 - Android Studio + SDK + Java (เฉพาะ Android)

ต้องมี Android Studio, Android SDK, และ **Java 17** (ระบุใน `android/app/build.gradle.kts`).
ตรวจ: `java -version`
ถ้าใช้ Windows Desktop อย่างเดียว ไม่ต้องติดตั้งส่วนนี้.

---

## 5. STEP 5 - ติดตั้งและเปิด Docker Desktop

Windows ไม่มี `docker compose` ในตัว ต้องติดตั้ง Docker Desktop จาก `docker.com`.
เปิด Docker Desktop แล้วตรวจ: `docker --version`, `docker compose version`

---

## 6. STEP 6 - Node.js (เฉพาะ Developer)

ลูกค้าทั่วไปไม่ต้องติดตั้ง เพราะ backend รันผ่าน Docker.
Developer ที่รันตรง: Node 20 LTS, `npm install`, `npm start`.

---

## 7. STEP 7 - Copy Project จาก USB ไปยังเครื่อง เช่น `D:\EBookApp`

โฟลเดอร์ `.flutter-plugins`, `build/`, `node_modules/` มีที่อยู่ของเครื่องเดิม
ระบบจะสร้างใหม่เองด้วย `flutter pub get` / `npm ci`.

---

## 8. STEP 8 - สร้างไฟล์ .env

```powershell
cd D:\EBookApp
copy .env.example .env
```

เปิด `.env` แล้วเติม `MYSQL_ROOT_PASSWORD` และ `JWT_SECRET`. เก็บไฟล์ไว้เป็นความลับ.

---

## 9. STEP 9 - เริ่ม backend และ database

```powershell
docker compose up -d --build
```

---

## 10. STEP 10 - ตรวจ container

`docker compose ps` ควรเห็น `ebook-backend`, `ebook-mysql`, `ebook-phpmyadmin`
สถานะ running/healthy.

---

## 11. STEP 11 - ตรวจ database (phpMyAdmin)

เปิด `http://localhost:8090` เข้าด้วย `root` + รหัสผ่าน `MYSQL_ROOT_PASSWORD`.
ควรเห็นฐาน `ebook_db` มี 13 ตาราง.

---

## 12. STEP 12 - ตรวจ backend API

เปิด `http://localhost:5001/api/health` ควรเห็น `{"status":"OK"}`.
URL ที่แอปใช้อยู่ที่ `lib/services/api_config.dart`: `apiPort = 5001`.

- Windows/Web : `http://localhost:5001/api`
- Android emulator : `http://10.0.2.2:5001/api`
- โทรศัพท์จริง : ต้องใช้ IP ของเครื่อง server เช่น `http://192.168.1.100:5001/api`

---

## 13. STEP 13 - ติดตั้ง dependencies ของ Flutter

```powershell
cd D:\EBookApp\flutter_application_1
flutter pub get
```

---

## 14. STEP 14 - รันแอป Flutter

- Windows : `flutter run -d windows`
- Web : `flutter run -d chrome`
- Android : `flutter run` (ต่อ emulator/โทรศัพท์ก่อน)

ครั้งแรกบน windows ถ้าให้เปิด Developer Mode : `start ms-settings:developers`

---

## 15. STEP 15 - เข้าสู่ระบบและทดสอบ

บัญชี seed: `admin@gmail.com/admin123456`, `employee@gmail.com/employee123`,
`user1234@gmail.com/user1234`, `member@gmail.com/member1234`.
ควรเปลี่ยนรหัสผ่านก่อนใช้งานจริง.

---

## 16. Environment Variables

`MYSQL_ROOT_PASSWORD` (รหัส root MySQL), `JWT_SECRET` (sign JWT),
`PORT` (5000 ใน container), `PUBLIC_BASE_URL` (`http://localhost:5001`).
ไม่แสดงค่าลับจริงในคู่มือนี้.

---

## 17. Checklist สุดท้าย

- [ ] `flutter --version` = 3.41+
- [ ] `docker --version` ติดตั้ง
- [ ] `docker compose version` ใช้ได้
- [ ] `docker compose up -d --build` ไม่ error
- [ ] `docker compose ps` ทั้ง 3 running
- [ ] `http://localhost:8090` เข้าได้
- [ ] `http://localhost:5001/api/health` ตอบ OK
- [ ] `flutter pub get` ไม่ error
- [ ] `flutter run -d windows` เปิดได้
- [ ] login แล้วหน้ารายหนังสือแสดงข้อมูล MySQL

ปัญหาอื่น ให้ดู `TROUBLESHOOTING.md`