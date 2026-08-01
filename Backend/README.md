# 📚 E-Book RESTful API (Node.js + Express + MySQL / phpMyAdmin)

API สำหรับระบบคลังหนังสืออิเล็กทรอนิกส์ (E-Book Application) รองรับการทำงานร่วมกับ **XAMPP / phpMyAdmin** และ **Database Schema 13 ตาราง**

---

## 🛠️ 1. โครงสร้างโปรเจกต์ (Backend Architecture)

```text
Backend/
├── config/
│   └── db.js                 # ตัวจัดการเชื่อมต่อ MySQL Pool (mysql2/promise)
├── controllers/              # Business Logic สำหรับแต่ละตาราง
│   ├── authController.js
│   ├── userController.js
│   ├── kycController.js
│   ├── authorController.js
│   ├── categoryController.js
│   ├── bookController.js
│   ├── packageController.js
│   ├── subscriptionController.js
│   ├── bookmarkController.js
│   ├── historyController.js
│   ├── downloadController.js
│   ├── notificationController.js
│   └── auditLogController.js
├── routes/                   # Routing จัดกลุ่มตาม API Endpoints
│   ├── authRoutes.js         # /api/auth
│   ├── userRoutes.js         # /api/users
│   ├── kycRoutes.js          # /api/kyc
│   ├── authorRoutes.js       # /api/authors
│   ├── categoryRoutes.js     # /api/categories
│   ├── bookRoutes.js         # /api/books
│   ├── packageRoutes.js      # /api/packages
│   ├── subscriptionRoutes.js # /api/subscriptions
│   ├── bookmarkRoutes.js     # /api/bookmarks
│   ├── historyRoutes.js      # /api/history
│   ├── downloadRoutes.js     # /api/downloads
│   ├── notificationRoutes.js # /api/notifications
│   └── auditLogRoutes.js     # /api/audit-logs
├── .env                      # ไฟล์กำหนดค่าพอร์ตและการเชื่อมต่อฐานข้อมูล
├── database.sql              # คำสั่ง DDL สคริปต์สร้างฐานข้อมูล 13 ตารางและ Seed ข้อมูลตัวอย่าง
├── package.json              # กำหนด Dependencies (express, mysql2, cors, dotenv ฯลฯ)
└── server.js                 # Entry point หลักของ Express Server
```

---

## 🚀 2. ขั้นตอนการติดตั้งและรันระบบ (Quick Start)

### ขั้นตอนที่ 1: การตั้งค่า XAMPP และ phpMyAdmin
1. เปิดโปรแกรม **XAMPP Control Panel**
2. กดกดปุ่ม **Start** ที่โมดูล **Apache** และ **MySQL**
3. เปิดบราวเซอร์ไปที่ `http://localhost/phpmyadmin`
4. คลิกแถบ **Import** (นำเข้า) แล้วเลือกไฟล์ `database.sql` จากโฟลเดอร์ `Backend/`
5. กดปุ่ม **Go** ด้านล่างเพื่อสร้างฐานข้อมูล `ebook_db` และ 13 ตารางพร้อม Seed ข้อมูลทดสอบ

---

### ขั้นตอนที่ 2: การติดตั้ง Node.js Dependencies และรัน Server
1. เปิด Terminal ในโฟลเดอร์ `Backend`:
   ```bash
   cd Backend
   npm install
   ```
2. สตาร์ท Express Server:
   - **โหมดใช้งานจริง (Production):**
     ```bash
     npm start
     ```
   - **โหมดพัฒนา (Development Auto Reload):**
     ```bash
     npm run dev
     ```

---

## 🔑 3. ข้อมูลบัญชีผู้ใช้สำหรับทดสอบ (Mock Credentials)

| บทบาท (Role) | อีเมล (Email) | รหัสผ่าน (Password) |
| :--- | :--- | :--- |
| **Admin** | `admin@gmail.com` | `admin123456` |
| **Employee (Staff)** | `employee@gmail.com` | `employee123` |
| **User (General)** | `user1234@gmail.com` | `user1234` |
| **Premiere Member** | `member@gmail.com` | `member1234` |

---

## 📡 4. สรุป API Endpoints หลัก

- **Health Check:** `GET http://localhost:5000/api/health`
- **Auth:**
  - `POST /api/auth/login` - เข้าสู่ระบบ
  - `POST /api/auth/register` - ลงทะเบียนผู้ใช้ใหม่
  - `GET /api/auth/me?user_id=X` - ดึงโปรไฟล์ผู้ใช้งาน
- **Users:** `GET /api/users`, `PUT /api/users/:id/status`
- **KYC:** `GET /api/kyc`, `POST /api/kyc`, `PUT /api/kyc/:id/status`
- **Books:** `GET /api/books`, `GET /api/books/:id`, `POST /api/books`, `PUT /api/books/:id`, `DELETE /api/books/:id`
- **Packages & Subscriptions:** `GET /api/packages`, `GET /api/subscriptions`, `POST /api/subscriptions`
- **Bookmarks & History:** `GET /api/bookmarks`, `GET /api/history`, `POST /api/history`
