# System Requirements (ข้อกำหนดของระบบ)

Project นี้ **ไม่ได้** ระบุ Requirement ขั้นต่ำอย่างเป็นทางการ
ข้อกำหนดด้านล่างคือ **Recommended Requirements** ที่แนะนำ
อ้างอิงจากเทคโนโลยีจริงที่ Project ใช้ (Docker, MySQL 8.0, Node.js 20, Flutter 3.41+)

---

## ฮาร์ดแวร์ (Hardware)

| รายการ | แนะนำ |
| ------ | ----- |
| OS | Windows 10 หรือ 11 (64-bit) |
| CPU | x86-64, 4 คอร์ขึ้นไป |
| RAM | 8 GB ขั้นต่ำ, 16 GB แนะนำ |
| พื้นที่เก็บข้อมูล | 30 GB ขึ้นไป (ติดตั้ง Flutter SDK + Docker images + Project) |
| Virtualization | ต้องเปิด VT-x / AMD-V ใน BIOS (จำเป็นสำหรับ Docker) |
| USB | อย่างน้อย 8 GB สำหรับส่ง Project (ตามขนาด Project ที่ Copy) |

---

## ซอฟต์แวร์ (Software)

| ซอฟต์แวร์ | เวอร์ชันที่ต้องการ | เหตุผล |
| ------ | ------ | ------ |
| Docker Desktop | ล่าสุด | รัน backend + MySQL + phpMyAdmin (ต้องมี `docker compose`) |
| Dart SDK / Flutter | Flutter 3.41.0+ (Dart 3.10+) | เงื่อนไขจาก `pubspec.yaml` และ `GEMINI.md` เพราะแพ็ก `pdfrx` |
| Visual Studio 2022+ | workload "Desktop development with C++" | เพื่อ `flutter run -d windows` |
| Android Studio + SDK | ล่าสุด | เฉพาะเมื่อ build ไป Android |
| Java (JDK) | 17 | ระบุใน `android/app/build.gradle.kts` เฉพาะ Android |
| Node.js | 20 LTS | เฉพาะ Developer ที่รัน backend ตรง (ไม่ใช้ Docker) |
| Git | แนะนำ (ไม่จำเป็น) | ถ้าจะ clone ใหม่ แทนการ Copy ผ่าน USB |

---

## เครือข่าย (Network)

- อินเทอร์เน็ต ครั้งแรกเพื่อ Download: dependencies (npm/pub), Docker images
- ถ้ารันโทรศัพท์ Android จริง: เครื่อง server กับโทรศัพท์ต้องอยู่ network เดียวกัน
  และต้องเปิด port 5001 บน Windows Firewall

---

## พอร์ตที่ Project ใช้ (จริงจาก docker-compose.yml)

| Service | Host Port | Container Port |
| ------ | :---: | :---: |
| backend | 5001 | 5000 |
| mysql | 3307 | 3306 |
| phpmyadmin | 8090 | 80 |

> หมายเหตุ: 5000 ถูกใช้เป็นพอร์ตภายใน container ส่วน host ใช้ 5001
> (บน macOS 5000 ถูก AirPlay Receiver กอครอง)

---

## เวอร์ชันที่ต้อง "ตรวจสอบจากเครื่องมือ"

ถ้าต้องการเวอร์ชันเจาะจงจริง ตรวจได้จากคำสั่ง:

```powershell
flutter --version
docker --version
docker compose version
node --version
npm --version
java -version
```