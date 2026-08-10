-- ============================================================
-- ຖານຂໍ້ມູນสำหรับໂຄງການ E-Book Application (ebook_db)
-- ຮອງຮັບການນຳເຂົ້າຜ່ານ phpMyAdmin / MySQL / PostgreSQL Server
-- ============================================================

-- This file is UTF-8 and holds Lao text. Declare the connection charset before
-- any data flows, otherwise a client that defaults to latin1 (the mysql client
-- in the Docker image does, because the container has no locale set) makes the
-- server re-encode every byte and stores mojibake such as "àº§àº´àº—".
SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS ebook_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ebook_db;

-- 1. ຕາຕະລາງຜູ້ໃຊ້ງານ (Users)
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) UNIQUE,
    birth_date DATE,
    gender ENUM('male', 'female', 'other', 'unspecified') DEFAULT 'unspecified',
    profile_image_url VARCHAR(500),
    role ENUM('admin', 'employee', 'user') DEFAULT 'user',
    status ENUM('active', 'suspended', 'banned', 'pending') DEFAULT 'active',
    suspended_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. ຕາຕະລາງການຢືນຢັນຕົວຕົນ (KYC Verifications)
CREATE TABLE IF NOT EXISTS kyc_verifications (
    kyc_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    full_name VARCHAR(255),
    gender VARCHAR(20) DEFAULT 'male',
    date_of_birth DATE,
    document_type ENUM('national_id', 'passport', 'student_card') NOT NULL,
    document_number VARCHAR(100) NOT NULL,
    document_image_url VARCHAR(500) NOT NULL,
    selfie_image_url VARCHAR(500),
    document_expiry_date DATE,
    is_student BOOLEAN DEFAULT FALSE,
    school_name VARCHAR(255),
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    reviewed_by INT,
    rejection_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (reviewed_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- 3. ຕາຕະລາງນັກຂຽນ (Authors)
CREATE TABLE IF NOT EXISTS authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. ຕາຕະລາງໝວດໝູ່ປຶ້ມ (Categories)
CREATE TABLE IF NOT EXISTS categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. ຕາຕະລາງປຶ້ມ (Books - อัปเดตเพิ่ม is_free_download)
CREATE TABLE IF NOT EXISTS books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author_id INT NOT NULL,
    language ENUM('LA', 'TH', 'EN', 'JP', 'CN') DEFAULT 'LA',
    page_count INT DEFAULT 0,
    file_size_bytes BIGINT DEFAULT 0, -- ขนาดไฟล์ PDF เป็น Bytes สำหรับแสดงใน Flutter
    description TEXT,
    cover_image_url VARCHAR(500),
    file_pdf_url VARCHAR(500) NOT NULL,
    uploaded_by INT NOT NULL,              -- FK ไปยัง users (Employee ที่อัปโหลด)
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending', -- 🟢 สถานะการอนุมัติ
    approved_by INT,                       -- 🟢 FK ไปยัง users (Admin ผู้อนุมัติ)
    rejection_reason TEXT,                 -- 🟢 เหตุผลที่ไม่อนุมัติ (ถ้ามี)
    is_free BOOLEAN DEFAULT FALSE,         -- 🟢 อ่านออนไลน์ฟรีทุกคน
    is_free_download BOOLEAN DEFAULT FALSE, -- 🟢 ดาวน์โหลดฟรีทุกคน (ถ้า FALSE ต้องมีแพ็กเกจ)
    is_hidden BOOLEAN DEFAULT FALSE,       -- ซ่อนหนังสือฉุกเฉิน (แม้จะอนุมัติแล้ว)
    is_deleted BOOLEAN DEFAULT FALSE,      -- Soft delete (ไม่แสดงหนังสือที่ถูกลบ)
    readers_count INT DEFAULT 0,           -- จำนวนผู้เข้าอ่านทั้งหมด
    likes_count INT DEFAULT 0,             -- จำนวนคนกดใจทั้งหมด
    rating DECIMAL(3,1) DEFAULT 5.0,        -- คะแนนเรตติ้ง ( default 5.0 )
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES authors(author_id),
    FOREIGN KEY (uploaded_by) REFERENCES users(user_id),
    FOREIGN KEY (approved_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- 6. ຕາຕະລາງເຊື່ອມ ປຶ້ມ ກັບ ໝວດໝູ່ (Book Categories)
CREATE TABLE IF NOT EXISTS book_categories (
    book_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (book_id, category_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);

-- 7. ຕາຕະລາງແພັກເກດສະມາຊິກ (Packages)
CREATE TABLE IF NOT EXISTS packages (
    package_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    duration_days INT NOT NULL,
    is_for_student BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. ຕາຕະລາງການຊື້ແພັກເກດ ແລະ ການໂອນເງິນ (Subscriptions)
CREATE TABLE IF NOT EXISTS subscriptions (
    subscription_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    package_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    slip_image_url VARCHAR(500) NOT NULL,
    payment_method VARCHAR(50) DEFAULT 'bank_transfer',
    start_date TIMESTAMP NULL,
    end_date TIMESTAMP NULL,
    payment_status ENUM('pending', 'active', 'rejected', 'expired', 'cancelled') DEFAULT 'pending',
    approved_by INT,
    rejected_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (package_id) REFERENCES packages(package_id),
    FOREIGN KEY (approved_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- 9. ຕາຕະລາງປຶ້ມເລົ່ມໂປດ / ການກົດໃຈ (Bookmarks / Likes)
CREATE TABLE IF NOT EXISTS bookmarks (
    bookmark_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_bookmark (user_id, book_id) -- ป้องกันผู้ใช้กดใจเล่มเดิมซ้ำ
);

-- 10. ຕາຕະລາງປະຫວັດການອ່ານ (Reading History)
CREATE TABLE IF NOT EXISTS reading_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    last_page_read INT DEFAULT 1,
    progress_percent DECIMAL(5, 2) DEFAULT 0.00,
    last_read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_book (user_id, book_id)
);

-- 11. ຕາຕະລາງປະຫວັດການດາວໂຫຼດ (Downloads)
CREATE TABLE IF NOT EXISTS downloads (
    download_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    downloaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    device_info VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
);

-- 12. ຕາຕະລາງການແຈ້ງເຕືອນ (Notifications)
CREATE TABLE IF NOT EXISTS notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('kyc', 'subscription', 'system', 'new_book') DEFAULT 'system',
    is_read BOOLEAN DEFAULT FALSE,
    target_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 13. ຕາຕະລາງບັນທຶກການເຮັດວຽກຂອງແອດມິນ/ພະນັກງານ (Audit Logs)
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    action VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ============================================================
-- ຂໍ້ມູນເລີ່ມຕົ້ນ (Seed Initial Data - ພາສາລາວ)
-- ============================================================

-- 1. Insert Initial Users
INSERT INTO users (user_id, email, password_hash, first_name, last_name, phone_number, role, status) VALUES
-- # ເຮັດຫຍັງ: ປ່ຽນ password_hash ຂອງ 4 ບັນຊີ seed ເປັນ bcrypt hash ຈິງ
-- # ຍ້ອນຫຍັງ: ຂອງເກົ່າໃຊ້ສະຕຣິງດຽວກັນທັງ 4 ບັນຊີ ແລະ ຍາວພຽງ 50 ຕົວອັກສອນ
-- #          (bcrypt ຈິງຕ້ອງ 60) ຈຶ່ງເປັນ hash ປອມທີ່ bcrypt.compare ບໍ່ມີວັນຜ່ານ
-- #          ບັນຊີເຫຼົ່ານີ້ຈຶ່ງ login ໄດ້ຍ້ອນ allowedPasswords ໃນ authController ເທົ່ານັ້ນ
-- #          ພໍຕັດ backdoor ນັ້ນອອກ ບັນຊີ seed ທັງໝົດຈຶ່ງເຂົ້າບໍ່ໄດ້
-- # ແກ້ຈາກສ່ວນໃດ: INSERT INTO users ທີ່ວາງ hash ປອມອັນດຽວກັນໃສ່ທຸກແຖວ
-- # ແກ້ເຮັດຫຍັງ: ແຕ່ລະບັນຊີມີ hash ຂອງລະຫັດຕົນເອງຕາມທີ່ເອກະສານ (GEMINI.md ຂໍ້ 3) ບອກ
-- #             ຈຶ່ງ login ຜ່ານ bcrypt ໄດ້ຈິງ ໂດຍບໍ່ຕ້ອງມີທາງລັດໃດໆ
(1, 'admin@gmail.com', '$2a$10$sJk.z11/HowyVD5ZBcnoEubM3Qrof4I0ABsiwSx/d0mwKgwNyQZ5y', 'ຜູ້ດູແລ', 'ລະບົບ (Admin)', '02055551111', 'admin', 'active'),
(2, 'employee@gmail.com', '$2a$10$k.qcjb1AdPRs54cD8L7l4OCuXivqUSaO02UXbGOiZl7XPq4lSjyF2', 'ພະນັກງານ', 'ຈັດການຄັງ', '02055552222', 'employee', 'active'),
(3, 'user1234@gmail.com', '$2a$10$p528LXEWFj12UA1BnMXkUueuB63.LH5uFGyqqJ41XMQJ5qrMYH0be', 'ສົມຊາຍ', 'ໃຈດີ', '02055553333', 'user', 'active'),
(4, 'member@gmail.com', '$2a$10$/5uivn1mIj10.jV4mgnN/O5sJtVjIEBSRv6sNqKQ5PKyijceTo8EG', 'ພຣີມ່ຽມ', 'ສະມາຊິກ', '02055554444', 'user', 'active')
ON DUPLICATE KEY UPDATE email=email;

-- 2. Insert Authors
INSERT INTO authors (author_id, name, biography) VALUES
(1, 'Stephen T. Radentz', 'ຜູ້ຂຽນປຶ້ມດ້ານການພັດທະນາຕົນເອງ ແລະ ຄວາມສຸກໃນການເຮັດວຽກ'),
(2, 'Dr. Elias Thorne', 'ອາຈານ ແລະ ນັກວິໄຈດ້ານຟິຊິກຄວອນຕຳ ແລະ ເຕັກໂນໂລຊີສະໄໝໃໝ່'),
(3, 'ດຣ.ຈອນ ວົງວິໄລ', 'ຜູ້ຊ່ຽວຊານດ້ານສັງຄົມສາດ ແລະ ປະຫວັດສາດ'),
(4, 'Nageen Prakashan', 'ສຳນັກພິມປຶ້ມວິທະຍາສາດ ແລະ ຄະນິດສາດ')
ON DUPLICATE KEY UPDATE name=name;

-- 3. Insert Categories
INSERT INTO categories (category_id, name) VALUES
(1, 'ຊີວະປະຫວັດ / ຊີວິດ'),
(2, 'ວິທະຍາສາດ / Physics'),
(3, 'ເຕັກໂນໂລຊີ / Computer'),
(4, 'ສິນລະປະ / ວັນນະຄະດີ'),
(5, 'ຄະນິດສາດ')
ON DUPLICATE KEY UPDATE name=name;

-- 4. Insert Packages
INSERT INTO packages (package_id, name, description, price, duration_days, is_for_student, is_active) VALUES
(1, 'Standard Monthly', 'ເຂົ້າເຖິງປຶ້ມອ່ານຟຣີ ແລະ ສະມາຊິກທົ່ວໄປ 30 ວັນ', 49000.00, 30, FALSE, TRUE),
(2, 'Student Special', 'ແພັກເກດພິເສດสำหรับນັກຮຽນ/ນັກສຶກສາ ຢືນຢັນຜ່ານ KYC', 29000.00, 30, TRUE, TRUE),
(3, 'Premium Yearly', 'ເຂົ້າເຖິງປຶ້ມທຸກເລົ່ມໃນຄັງແບບບໍ່ຈຳກັດ 365 ວັນ', 490000.00, 365, FALSE, TRUE)
ON DUPLICATE KEY UPDATE name=name;

-- 5. Insert Books (มี is_free, is_free_download, status, approved_by, rejection_reason, readers_count, likes_count)
-- # ເຮັດຫຍັງ: ປ່ຽນ cover_image_url ຂອງ seed ໃຫ້ຊີ້ໄປ assets/BookCover.jpg
-- # ຍ້ອນຫຍັງ: ຂອງເກົ່າອ້າງ happiness/science/quantum/social_cover.jpg ເຊິ່ງ 4 ໄຟລ໌ນີ້
-- #          ບໍ່ເຄີຍມີໃນ flutter_application_1/assets/ ເລີຍ (ມີແຕ່ BookCover.jpg
-- #          ກັບ QRcodeDemo.svg) ທຸກປຶ້ມຈຶ່ງໂຫຼດຮູບບໍ່ໄດ້ ແລ້ວຕົກໄປໃຊ້ placeholder
-- #          ພ້ອມ 404 ເຕັມ console ຂອງ browser
-- # ແກ້ຈາກສ່ວນໃດ: ຄ່າ cover_image_url ໃນ INSERT INTO books
-- # ແກ້ເຮັດຫຍັງ: ຊີ້ໄປໄຟລ໌ທີ່ມາພ້ອມແອັບຈິງ ຮູບຈຶ່ງຂຶ້ນ ແລະ ບໍ່ມີ 404 ອີກ
-- #             (ເມື່ອມີຮູບປົກຈິງແລ້ວ ໃຫ້ອັບໂຫຼດຜ່ານໜ້າ Employee ແທນ)
INSERT INTO books (book_id, title, author_id, language, page_count, file_size_bytes, description, cover_image_url, file_pdf_url, uploaded_by, status, approved_by, rejection_reason, is_free, is_free_download, is_hidden, readers_count, likes_count) VALUES
(1, 'The Happiness Effect', 1, 'EN', 240, 15400000, 'ປຶ້ມຖ່າຍທອດເລື່ອງราวການສ້າງຄວາມສຸກ ແລະ ການມອງໂລກໃນແງ່ດີ', 'assets/BookCover.jpg', 'assets/sample_book.pdf', 2, 'approved', 1, NULL, TRUE, TRUE, FALSE, 125, 42),
(2, 'High School Science (ວິທະຍາສາດ)', 4, 'LA', 310, 22100000, 'ຕຳລາຮຽນວິທະຍາສາດລະດັບມັດທະຍົມປາຍ ຄອບຄຸມພື້ນຖານຟິຊິກ ເຄມີ ຊີວະວິທະຍາ', 'assets/BookCover.jpg', 'assets/sample_book.pdf', 2, 'approved', 1, NULL, TRUE, FALSE, FALSE, 88, 31),
(3, 'Quantum Mechanics', 2, 'EN', 450, 38000000, 'ເຈາະລຶກທິດສະດີຄວອນຕຳ ແລະ ກົນລະສາດສະໄໝໃໝ່', 'assets/BookCover.jpg', 'assets/sample_book.pdf', 2, 'approved', 1, NULL, FALSE, FALSE, FALSE, 64, 19),
(4, 'ປຶ້ມສັງຄົມສຶກສາ', 3, 'LA', 180, 12000000, 'ຄວາມຮູ້ກ່ຽວກັບສັງຄົມ ວັດທະນະທຳ ແລະ ພູມສາດ', 'assets/BookCover.jpg', 'assets/sample_book.pdf', 2, 'approved', 1, NULL, TRUE, TRUE, FALSE, 210, 95),
(5, 'Advances in Physics (ລໍຖ້າອະນຸມັດ)', 2, 'EN', 280, 18500000, 'ຕຳລາຟິຊິກຂັ້ນສູງ ສຳລັບນັກຮຽນ ແລະ ນັກວິໄຈ', 'assets/BookCover.jpg', 'assets/sample_book.pdf', 2, 'pending', NULL, NULL, TRUE, FALSE, FALSE, 0, 0)
ON DUPLICATE KEY UPDATE title=title;

-- 6. Insert Book Categories
INSERT INTO book_categories (book_id, category_id) VALUES
(1, 1),
(2, 2),
(3, 2),
(3, 3),
(4, 4),
(5, 2)
ON DUPLICATE KEY UPDATE book_id=book_id;

-- 7. Insert Subscriptions
INSERT INTO subscriptions (subscription_id, user_id, package_id, amount, slip_image_url, payment_status, approved_by, start_date, end_date) VALUES
(1, 4, 3, 490000.00, 'slips/sample_slip.jpg', 'active', 1, NOW(), DATE_ADD(NOW(), INTERVAL 365 DAY))
ON DUPLICATE KEY UPDATE subscription_id=subscription_id;

-- 8. Insert KYC Verifications
INSERT INTO kyc_verifications (kyc_id, user_id, document_type, document_number, document_image_url, selfie_image_url, is_student, school_name, status) VALUES
(1, 3, 'national_id', '1-1002-34567-89-0', 'kyc/id_card_001.jpg', 'kyc/selfie_001.jpg', FALSE, NULL, 'pending'),
(2, 4, 'student_card', 'STU-99887766', 'kyc/id_card_002.jpg', 'kyc/selfie_002.jpg', TRUE, 'ມະຫາວິທະຍາໄລແຫ່ງຊາດ', 'approved')
ON DUPLICATE KEY UPDATE kyc_id=kyc_id;

-- 9. Insert Bookmarks
INSERT INTO bookmarks (bookmark_id, user_id, book_id) VALUES
(1, 3, 1),
(2, 3, 2)
ON DUPLICATE KEY UPDATE bookmark_id=bookmark_id;

-- 10. Insert Reading History
INSERT INTO reading_history (history_id, user_id, book_id, last_page_read, progress_percent) VALUES
(1, 3, 4, 81, 45.00),
(2, 3, 1, 240, 100.00)
ON DUPLICATE KEY UPDATE history_id=history_id;

-- 11. Insert Downloads
INSERT INTO downloads (download_id, user_id, book_id, device_info) VALUES
(1, 3, 4, 'Flutter Application'),
(2, 3, 3, 'Flutter Application')
ON DUPLICATE KEY UPDATE download_id=download_id;

-- # ເຮັດຫຍັງ: ເພີ່ມຂໍ້ມູນຕົວຢ່າງໃສ່ຕາຕະລາງ notifications
-- # ຍ້ອນຫຍັງ: ເປັນຕາຕະລາງດຽວ (ນອກຈາກ audit_logs ທີ່ສ້າງຕອນແລ່ນ) ທີ່ seed ບໍ່ມີ
-- #          ແອັບຈຶ່ງເຄີຍ fallback ໄປໃຊ້ MockNotificationsData ທີ່ hardcode ໄວ້ໃນໂຄ້ດ
-- #          ຜູ້ໃຊ້ຈຶ່ງເຫັນແຈ້ງເຕືອນປອມທີ່ບໍ່ແມ່ນຂອງຕົນ ແລະ ລຶບບໍ່ໄດ້
-- # ແກ້ຈາກສ່ວນໃດ: database.sql ມີ INSERT ໃຫ້ 11 ຕາຕະລາງ ແຕ່ຂ້າມ notifications
-- # ແກ້ເຮັດຫຍັງ: ຂໍ້ມູນຕົວຢ່າງມາຈາກຖານຂໍ້ມູນ ຈຶ່ງອ່ານ/ໝາຍວ່າອ່ານແລ້ວ/ລຶບໄດ້ຈິງ
-- #             ຜ່ານ API ດຽວກັນກັບຂໍ້ມູນຈິງ
INSERT INTO notifications (notification_id, user_id, title, message, type, is_read) VALUES
(1, 3, '🎉 ຍິນດີຕ້ອນຮັບເຂົ້າສູ່ລະບົບ E-Book', 'ເລີ່ມຄົ້ນຫາ ແລະ ອ່ານປຶ້ມທີ່ທ່ານສົນໃຈໄດ້ເລີຍ', 'system', TRUE),
(2, 3, '🛡️ ຢືນຢັນຕົວຕົນ (KYC) ຜ່ານແລ້ວ', 'ບັນຊີຂອງທ່ານຜ່ານການກວດສອບ ສາມາດສະໝັກແພັກເກັດສະມາຊິກໄດ້', 'kyc', TRUE),
(3, 3, '📚 ມີປຶ້ມໃໝ່ເຂົ້າຄັງ', 'ປຶ້ມສັງຄົມສຶກສາ ຖືກເພີ່ມເຂົ້າຄັງແລ້ວ ລອງເປີດອ່ານເບິ່ງ', 'new_book', FALSE),
(4, 4, '👑 ທ່ານເປັນສະມາຊິກ Premiere ແລ້ວ', 'ອ່ານ ແລະ ດາວໂຫຼດ e-Book ໄດ້ແບບບໍ່ຈຳກັດຕະຫຼອດອາຍຸແພັກເກັດ', 'subscription', FALSE),
(5, 2, '📥 ມີປຶ້ມລໍຖ້າການອະນຸມັດ', 'Advances in Physics ລໍຖ້າແອດມິນກວດສອບ ແລະ ອະນຸມັດ', 'system', FALSE)
ON DUPLICATE KEY UPDATE notification_id=notification_id;

