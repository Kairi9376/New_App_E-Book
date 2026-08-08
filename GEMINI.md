# 📚 Flutter E-Book Application Guide (GEMINI.md)

ยินดีต้อนรับสู่คู่มือพัฒนาและสถาปัตยกรรมของโครงการ **New_App_E-Book (Flutter Application)** แอปพลิเคชันอ่านและจัดการหนังสืออิเล็กทรอนิกส์ (E-Book) รองรับทั้งระบบ Web (Chrome) และ Mobile

---

## 🚀 1. ภาพรวมโปรเจกต์ (Project Overview)

โปรเจกต์นี้เป็นแอปพลิเคชันอ่านหนังสือ E-Book และระบบบริหารจัดการคลังหนังสือในรูปแบบไฟล์เอกสาร **PDF** โดยแบ่งบทบาทผู้ใช้งานและการเข้าถึงออกเป็น 3 ระดับอย่างชัดเจน:
- **General User / Premiere Member:** หน้าแรกค้นหาหนังสือ อ่านเรื่องย่อ คั่นหน้าหนังสือ บันทึกประวัติ และรายการดาวน์โหลด
- **Employee (พนักงาน/Staff):** ระบบพนักงานสำหรับเพิ่มหนังสือเข้าคลัง รองรับการแนบไฟล์เอกสาร PDF, อัปโหลดภาพปก, กรอกรายละเอียดเรื่องย่อ และดูตัวอย่าง (Live Preview)
- **Admin (ผู้ดูแลระบบ):** แดชบอร์ดภาพรวม จัดการผู้ใช้งาน ดูสถิติรายงาน และควบคุมระบบ

---

## 🛠️ 2. โครงสร้างโปรเจกต์ (Project Directory Structure)

```text
flutter_application_1/
├── lib/
│   ├── main.dart                       # จุดเริ่มต้นของแอปพลิเคชัน (Entry point)
│   ├── models/                         # Data Models & Mock Data
│   │   ├── book_model.dart             # โครงสร้างข้อมูลหนังสือ & ข้อมูลจำลอง
│   │   ├── downloads_model.dart        # โครงสร้างข้อมูลดาวน์โหลด
│   │   ├── history_model.dart          # โครงสร้างข้อมูลประวัติการอ่าน
│   │   └── saved_model.dart            # โครงสร้างข้อมูลหนังสือที่บันทึก
│   ├── theme/
│   │   └── app_theme.dart              # ระบบสี Font และ ThemeData
│   └── screens/                        # หน้า UI แยกตาม Role
│       ├── login_screen.dart           # หน้าเข้าสู่ระบบตามสิทธิ์ (Role-based Authentication)
│       ├── user_home_screen.dart       # หน้าหลักผู้ใช้งานทั่วไป (Home & Catalog)
│       ├── book_detail_screen.dart     # หน้ารายละเอียดหนังสือ
│       ├── downloads_screen.dart       # หน้าคลังดาวน์โหลด
│       ├── history_screen.dart         # หน้าประวัติการเข้าชม
│       ├── saved_screen.dart           # หน้าหนังสือที่บันทึกไว้
│       ├── profile_screen.dart         # หน้าโปรไฟล์ผู้ใช้
│       ├── admin/                      # ส่วนของผู้ดูแลระบบ (Admin)
│       │   ├── admin_dashboard_screen.dart  # แดชบอร์ด Admin (ผู้ใช้, รายงาน, ตั้งค่า)
│       │   └── admin_book_dialog.dart       # Dialog เพิ่ม/แก้ไขหนังสือแบบเร็ว
│       └── employee/                   # ส่วนของพนักงาน (Employee / Staff)
│           ├── employee_dashboard_screen.dart # แดชบอร์ดพนักงาน (คลัง PDF)
│           └── add_book_screen.dart          # หน้าฟอร์มเพิ่มหนังสือ PDF เต็มรูปแบบ
├── web/
│   └── index.html                      # Web Entry point (ปรับใช้ flutter.js loader)
└── pubspec.yaml                        # กำหนด Dependencies & SDK constraints
```

---

## 🔑 3. บัญชีเข้าสู่ระบบทดสอบ (Mock Credentials)

| บทบาท (Role) | อีเมล (Email) | รหัสผ่าน (Password) | หน้าจอเป้าหมาย (Destination) |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin@gmail.com` | `admin123456` | [AdminDashboardScreen](file:///d:/Github/New_App_E-Book/flutter_application_1/lib/screens/admin/admin_dashboard_screen.dart) |
| **Employee (Staff)** | `employee@gmail.com` | `employee123` | [EmployeeDashboardScreen](file:///d:/Github/New_App_E-Book/flutter_application_1/lib/screens/employee/employee_dashboard_screen.dart) |
| **User (General)** | `user1234@gmail.com` | `user1234` | [UserHomeScreen](file:///d:/Github/New_App_E-Book/flutter_application_1/lib/screens/user_home_screen.dart) |
| **Premiere Member** | `member@gmail.com` | `member1234` | [UserHomeScreen](file:///d:/Github/New_App_E-Book/flutter_application_1/lib/screens/user_home_screen.dart) (พร้อมตรา Premiere) |

---

## ⚡ 4. ข้อควรระวังและการพัฒนาสำคัญ (Technical Standards)

### A. การจัดการรูปภาพบน Web (`kIsWeb`)
- บนบราวเซอร์ (Chrome) **ห้าม** เรียกใช้ `File(path).existsSync()` จาก `dart:io` โดยตรงเพราะจะเกิด `Unsupported operation: _Namespace`
- ให้ใช้ฟังก์ชัน `_buildImage` ที่ครอบด้วย `kIsWeb` เช็ค `Image.network` หรือ `Image.asset` เสมอ

### B. การสลับหน้าจอ (Navigation & Route Transition)
- เพื่อป้องกันปัญหา `Cannot hit test a render box that has never been laid out` บนบราวเซอร์ การสลับหน้าหลักควรใช้ `PageRouteBuilder` ร่วมกับ `transitionDuration: Duration.zero` และ `FocusScope.of(context).unfocus()`

### C. การรองรับไฟล์ PDF
- ระบบพนักงานออกแบบมาสำหรับการแนบไฟล์เอกสาร PDF (`.pdf`) รองรับขนาดไฟล์สูงสุด 100MB พร้อมระบบจำลอง Progress และ Live Preview

### D. การแสดงผลเนื้อหาไฟล์ PDF และระบบเลือกหน้า (PDF Page Rendering & Single-Page View)
- **แสดงเนื้อหาจากไฟล์ PDF เท่านั้น:** การเปิดอ่านหนังสือ E-Book ต้องแสดงผลเนื้อหาภาพ/ข้อความจริงจากไฟล์เอกสาร PDF ในแต่ละหน้าผ่าน PDF.js Canvas ห้ามนำข้อมูลรายละเอียดหนังสือ (Synopsis/Description) จากฐานข้อมูลมาแสดงเป็นตัวหนังสือจำลองในหน้าอ่านโดยเด็ดขาด
- **การนับจำนวนหน้าจริง (`numPages`):** ระบบจะอ่านจำนวนหน้าจริงจากไฟล์ PDF อัตโนมัติผ่าน PDF.js และจำกัดการสลับหน้าไม่ให้เกินจำนวนหน้าที่มีอยู่จริงในไฟล์เอกสาร PDF
- **ระบบเลือกหน้า (Page Selection):** แสดงตัวเลือกหน้าเป็น `ໜ້າ 1`, `ໜ້າ 2`, `ໜ້າ 3`... ตามลำดับตัวเลขหน้าจริง ห้ามแสดงเป็นหัวข้อบทเรียนจำลอง พร้อมระบบกระโดดข้ามหน้าด่วน (Direct Page Jump)
- **การจัดการ Pointer Events บน Web:** เมื่อเปิด Modal/Dialog เลือกหน้าบน Flutter Web ต้องตั้งค่า `pointerEvents = 'none'` บน iframe ชั่วคราวเพื่อป้องกัน iframe แย่งจับ Event การคลิกเมาส์

### E. การแยกหน้า Login ตาม Role (Platform Gate)

หน้า Login ถูกแยกออกเป็น 2 หน้าตามกลุ่มสิทธิ์ และผูกกับ platform อย่างเคร่งครัด

| กลุ่มสิทธิ์ | Role ในฐานข้อมูล | หน้า Login | ใช้ได้บน |
| :--- | :--- | :--- | :--- |
| **Staff** | `admin`, `employee` | [`StaffLoginScreen`](flutter_application_1/lib/screens/login_screen.dart) | **Web เท่านั้น** |
| **Customer** | `user` (รวม Premiere Member) | [`UserLoginScreen`](flutter_application_1/lib/screens/User/user_login_screen.dart) | **Flutter App เท่านั้น** |

- **แหล่งความจริงเดียว:** กติกาว่า role ไหนเข้า platform ไหนได้อยู่ที่ [`AuthGate`](flutter_application_1/lib/services/auth_gate.dart) ที่เดียว ห้ามเขียนเงื่อนไข `role == 'admin'` กระจายตามหน้าจอ
- **"Member" ไม่ใช่ role:** ฐานข้อมูลมีแค่ 3 role (`admin`, `employee`, `user`) ส่วน Premiere Member คือ `user` ที่มี subscription อยู่ จึงถูกจัดเป็นกลุ่ม Customer
- **ต้องล้าง session เมื่อ role ไม่ตรง platform:** `ApiService.login` บันทึก session ทันทีที่ยิง API สำเร็จ การแค่ไม่ `Navigator.push` ต่อไม่พอ ต้องเรียก `ApiService.clearSession()` ด้วย มิฉะนั้น session จะค้างแล้วถูกกู้คืนตอนเปิดใหม่ กลายเป็นช่องรั่ว จุดนี้ถูกบังคับซ้ำอีกชั้นใน `AppInitializer` ของ [`main.dart`](flutter_application_1/lib/main.dart)
- **สมัครสมาชิกเองได้เฉพาะฝั่ง App:** ลิงก์ลงทะเบียนอยู่บน `UserLoginScreen` เท่านั้น เพราะบัญชีที่สมัครเองจะได้ `role=user` ซึ่ง login บน Web ไม่ได้อยู่แล้ว

---

## 🐳 5. การรัน Backend ด้วย Docker (Docker Stack)

Backend, ฐานข้อมูล และ phpMyAdmin ทั้งหมดรันผ่าน [`docker-compose.yml`](docker-compose.yml) ที่ root ของโปรเจกต์ ไม่ต้องติดตั้ง Laragon/XAMPP หรือ Node.js บนเครื่องอีกต่อไป

### A. ตั้งค่าครั้งแรก (Required)

Compose อ่านค่าลับจากไฟล์ `.env` ที่ root **ต้องสร้างก่อนรัน** มิฉะนั้น Compose จะแทนค่าเป็นสตริงว่าง และ MySQL 8 จะปฏิเสธการ initialize เพราะรหัสผ่าน root ว่าง (ทำให้ backend และ phpMyAdmin ไม่ขึ้นตามไปด้วย)

```bash
cp .env.example .env
```

จากนั้นกรอกค่า `MYSQL_ROOT_PASSWORD` และ `JWT_SECRET` ในไฟล์ `.env` (ไฟล์นี้อยู่ใน `.gitignore` แล้ว ห้าม commit)

### B. คำสั่งที่ใช้บ่อย

```bash
docker compose up -d --build
```

```bash
docker compose ps
```

```bash
docker compose logs -f backend
```

```bash
docker compose down
```

### C. Services และ Port

| Service | Container | Port (Host → Container) | URL |
| :--- | :--- | :--- | :--- |
| **backend** | `ebook-backend` | `5001 → 5000` | http://localhost:5001 |
| **mysql** | `ebook-mysql` | `3307 → 3306` | — |
| **phpmyadmin** | `ebook-phpmyadmin` | `8090 → 80` | http://localhost:8090 |

> ⚠️ **ทำไม Port ฝั่ง Host ถึงไม่ตรงกับค่ามาตรฐาน:** พอร์ต 5000 ถูก AirPlay Receiver ของ macOS จองไว้ ส่วน 8080/8081 ถูกเซอร์วิสอื่นบนเครื่องใช้อยู่ ตัว container ยังฟังที่พอร์ตเดิม (5000/80) ภายใน Docker network ตามปกติ

### D. ข้อควรระวังสำคัญ

- **Flutter ต้องชี้พอร์ตให้ตรง:** ค่าพอร์ตฝั่ง client อยู่ที่ `ApiConfig.apiPort` ใน [`api_config.dart`](flutter_application_1/lib/services/api_config.dart) จุดเดียว หากแก้ `ports:` ของ service `backend` ต้องแก้ค่านี้ให้ตรงกันเสมอ
- **ห้าม hardcode URL ฝั่ง Backend:** URL ที่ส่งกลับไปให้ client ต้องสร้างจาก `clientOrigin(req)` ใน [`server.js`](Backend/server.js) ซึ่งอ่านจาก Host header ห้ามอิงตัวแปร `PORT` เพราะเป็นพอร์ตภายใน container (5000) ที่ client เข้าถึงไม่ได้ และยังรองรับ Android Emulator ที่เรียกผ่าน `10.0.2.2` ได้ถูกต้องด้วย
- **ฐานข้อมูล initialize ครั้งเดียว:** [`Backend/database.sql`](Backend/database.sql) จะถูกรันตอนที่ volume `mysql-data` ว่างเปล่าเท่านั้น หากแก้ schema หรือเปลี่ยน `MYSQL_ROOT_PASSWORD` ต้องล้าง volume ก่อนด้วย `docker compose down -v` (คำสั่งนี้ **ลบข้อมูลในฐานข้อมูลทั้งหมด**)
- **แก้โค้ด backend แล้วต้อง rebuild ไม่ใช่ restart:** `Dockerfile` ใช้ `COPY . .` โค้ดจึงถูก bake เข้า image ตั้งแต่ตอน build การสั่ง `docker compose restart backend` จะรันโค้ดเวอร์ชันเดิมต่อไปโดยไม่มีอะไรเตือน ต้องใช้:
  ```bash
  docker compose up -d --build backend
  ```
- **ไฟล์อัปโหลดอยู่ใน volume:** ไฟล์ใน `/app/uploads` เก็บใน named volume `backend-uploads` ไม่ได้ถูก build ติดไปกับ image จึงไม่หายเมื่อ rebuild

---

## 💻 6. คำสั่งในการรันโครงการ (Running the App)

### ข้อกำหนดขั้นต่ำ

**Flutter 3.41.0 ขึ้นไป** (Dart 3.10+) เพราะแพ็กเกจ `pdfrx` บังคับไว้ ตรวจด้วย `flutter --version`
ถ้าเก่ากว่านี้ `flutter pub get` จะฟ้องทันที ไม่ต้องรอไปพังตอน build

### ติดตั้ง Dependencies (ทำครั้งเดียว)

```bash
cd flutter_application_1
flutter pub get
```

### รัน 2 ส่วนตาม Role

**สำคัญ:** Admin Web กับ Flutter App เป็นโค้ดชุดเดียวกัน ต่างกันแค่ device ที่เลือกด้วย `-d`
`AuthGate` ใช้ `kIsWeb` ตัดสินว่าจะโชว์หน้า Login ตัวไหน (ดูหัวข้อ 4.E)

| ต้องการ | คำสั่ง | ได้หน้า Login |
| :--- | :--- | :--- |
| **Admin Web** | `flutter run -d chrome` | Staff (Admin/Employee) |
| **Flutter App** บน Windows | `flutter run -d windows` | User/Member |
| **Flutter App** บน macOS | `flutter run -d macos` | User/Member |
| **Flutter App** บนมือถือ | `flutter run` (ต่อ emulator/เครื่องจริงก่อน) | User/Member |

### สำหรับผู้พัฒนาบน Windows

Windows คือ target หลักของฝั่ง Flutter App สำหรับทีมที่ทำงานบน Windows
ไม่ต้องติดตั้ง Android emulator ก็ทดสอบฝั่งผู้ใช้ได้

```bash
flutter run -d windows
```

ครั้งแรกต้องเปิด Developer Mode ของ Windows ก่อน (Flutter จะสั่งให้เอง) หรือรัน:

```bash
start ms-settings:developers
```

ต้องมี **Visual Studio** พร้อม workload *"Desktop development with C++"* ตรวจความพร้อมด้วย:

```bash
flutter doctor
```

> ⚠️ **Windows ไม่มี `docker compose` มาให้ในตัว** ต้องติดตั้ง Docker Desktop ก่อน แล้วจึงรัน
> คำสั่ง `docker compose up -d` ที่ root ของโปรเจกต์ตามหัวข้อ 5 ได้ตามปกติ

### ตรวจสอบวิเคราะห์ความถูกต้องของโค้ด

```bash
flutter analyze
```

### ทำไมโค้ดต้องมีชั้น platform คั่น

`dart:html` และ `dart:js` มีเฉพาะบน Web การ `import` ตรง ๆ ทำให้ **build ลง Windows/macOS/
iOS/Android ไม่ผ่านทั้งหมด** ตั้งแต่ขั้น compile และการครอบด้วย `if (kIsWeb)` ช่วยไม่ได้
เพราะ compiler ต้อง resolve import ให้จบก่อนถึง runtime

โค้ดที่แตะ DOM จึงถูกรวมไว้ที่ [`lib/services/platform/`](flutter_application_1/lib/services/platform/)
แล้วเลือก implementation ด้วย conditional export:

| ไฟล์ | ใช้ตอน |
| :--- | :--- |
| `web_platform.dart` | facade เลือกให้อัตโนมัติ - โค้ดอื่น import ตัวนี้ตัวเดียว |
| `web_platform_web.dart` | build ลง Web (ที่เดียวที่ยัง `import 'dart:html'` ได้) |
| `web_platform_stub.dart` | build ลง Windows/macOS/iOS/Android |

**ห้าม `import 'dart:html'` หรือ `'dart:js'` ในไฟล์อื่นนอกจาก `web_platform_web.dart`**

### ความต่างของ 2 ฟีเจอร์ระหว่าง Web กับ App

ทั้งสองใช้งานได้ครบทุก platform แล้ว แต่เบื้องหลังคนละตัว:

| ฟีเจอร์ | บน Web | บน Windows/macOS/มือถือ |
| :--- | :--- | :--- |
| อ่าน PDF | PDF.js ใน iframe | `pdfrx` (PDFium) |
| เลือกไฟล์อัปโหลด | `dart:html` FileUploadInputElement | `file_picker` |

บน macOS การอัปโหลดต้องมีสิทธิ์ `com.apple.security.files.user-selected.read-only`
และการต่อ backend ต้องมี `com.apple.security.network.client` ใน
[`DebugProfile.entitlements`](flutter_application_1/macos/Runner/DebugProfile.entitlements)
และ [`Release.entitlements`](flutter_application_1/macos/Runner/Release.entitlements)
