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

---

## 💻 5. คำสั่งในการรันโครงการ (Running the App)

1. **ติดตั้ง Dependencies:**
   ```bash
   cd flutter_application_1
   flutter pub get
   ```

2. **รันบน Google Chrome:**
   ```bash
   flutter run -d chrome
   ```

3. **ตรวจสอบวิเคราะห์ความถูกต้องของโค้ด:**
   ```bash
   flutter analyze
   ```
