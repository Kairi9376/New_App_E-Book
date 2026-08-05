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
│       │   ├── admin_book_dialog.dart       # Full Screen ฟอร์มเพิ่ม/แก้ไขหนังสือ (AdminBookFormScreen)
│       │   └── admin_user_dialog.dart       # Full Screen ฟอร์มเพิ่ม/แก้ไขผู้ใช้ (AdminUserFormScreen)
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

### D. ⛔ ห้ามใช้ showDialog สำหรับฟอร์มที่ซับซ้อนบน Flutter Web (Critical)
- บน Flutter Web การใช้ `showDialog()` สำหรับฟอร์มที่มี `GlobalKey<FormState>`, Dropdown, หรือ File Upload **จะทำให้เกิดข้อผิดพลาดร้ายแรง:**
  - `Cannot hit test a render box that has never been laid out (RenderErrorBox DISPOSED)`
  - `Multiple widgets used the same GlobalKey`
- **สาเหตุ:** Dialog อยู่ใน Overlay Tree ร่วมกับหน้าหลัก → เมื่อปิด Dialog, `MouseTracker` ของ Flutter Web ยังพยายาม `hitTest()` ที่ตำแหน่ง Widget ที่กำลัง Dispose → Crash ทันที
- **กฎเหล็ก:** ฟอร์มเพิ่ม/แก้ไขข้อมูล (Book, User, etc.) **ต้องใช้ `Navigator.push` + `Scaffold` (Full Screen Page) เสมอ** ตามรูปแบบฝั่ง Employee:
  ```dart
  // ✅ ถูกต้อง — Full Screen (ไม่มีปัญหาบน Web)
  void _openAddBookScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminBookFormScreen()),
    );
    if (result == true && mounted) _fetchAdminData();
  }

  // ❌ ห้ามใช้ — Dialog (Crash บน Web)
  void _openAddBookDialog() async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => const AdminBookDialog(),  // ⛔ ห้าม!
    );
  }
  ```
- **Loading Indicator:** ห้ามใช้ `showDialog` ซ้อนสำหรับแสดง Loading ภายในฟอร์ม ให้ใช้ `_isSaving` state + `Stack` overlay ภายในหน้า Scaffold แทน
- **Navigator.pop:** ต้อง pop **ครั้งเดียว** ด้วย `Navigator.pop(context, true)` เท่านั้น ห้าม pop 2 ครั้งติดกัน (ปิด Loading Dialog + ปิดฟอร์ม) เพราะจะเกิด Race Condition กับ MouseTracker

### E. กฎการใช้ `const` กับ Widget ที่มี Non-Const Constructor
- `CircularProgressIndicator()` **ไม่ใช่** const constructor → ห้ามครอบ Widget ตัวนอกด้วย `const` ถ้าข้างในมี `CircularProgressIndicator`
- วิธีที่ถูกต้อง: ย้าย `const` ลงมาวางที่ `children: const [...]` โดยตรง หรือใส่ `const` เฉพาะ Widget ลูกที่เป็น const ได้:
  ```dart
  // ✅ ถูกต้อง
  Column(
    children: const [
      CircularProgressIndicator(),
      SizedBox(height: 14),
      Text('Loading...', style: TextStyle(fontWeight: FontWeight.bold)),
    ],
  )

  // ❌ ผิด — จะเกิด error "The constructor being called isn't a const constructor"
  const Column(
    children: [
      CircularProgressIndicator(),  // ⛔ ไม่ใช่ const constructor!
    ],
  )
  ```

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
