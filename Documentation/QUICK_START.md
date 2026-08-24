# คู่มือเริ่มต้นใช้งานแบบเร็ว (QUICK START)

> สำหรับลูกค้าที่ติดตั้ง Software ครบแล้ว (Flutter, Docker Desktop, .env พร้อม)
> ถ้ายังไม่ได้ติดตั้ง ให้อ่าน `INSTALLATION_GUIDE.md` ก่อน

---

## 1. เปิด Docker Desktop

เปิดแอป Docker Desktop แล้วรอให้ Docker Engine พร้อม

---

## 2. เปิด Terminal ที่โฟลเดอร์หลักของ Project

```powershell
cd D:\EBookApp
```

(ใช้โฟลเดอร์จริงที่ลูกค้า Copy Project ไว้)

---

## 3. เริ่ม Backend + Database

```powershell
docker compose up -d --build
```

---

## 4. ตรวจสอบว่า Container พร้อม

```powershell
docker compose ps
```

ควรเห็น `ebook-backend`, `ebook-mysql`, `ebook-phpmyadmin` สถานะ running/healthy

---

## 5. ตรวจสอบ API ตอบสนอง

เปิดเว็บเบราว์เซอร์ไปที่ `http://localhost:5001/api/health`
ควรเห็น `{"status":"OK"}`

---

## 6. ติดตั้ง Dependencies ของ Flutter

```powershell
cd D:\EBookApp\flutter_application_1
flutter pub get
```

---

## 7. รันแอป

ตามบทบาทของลูกค้า:

- User/Member บน Windows : `flutter run -d windows`
- Admin/Employee บน Web : `flutter run -d chrome`
- บน Android : `flutter run`

---

## 8. Login

ใช้บัญชี seed เช่น `user1234@gmail.com / user1234`
ถ้าเห็นหน้ารายหนังสือ = ติดตั้งสำเร็จ

---

## ปัญหา?

ดู `TROUBLESHOOTING.md`