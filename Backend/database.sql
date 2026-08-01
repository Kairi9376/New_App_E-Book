-- ============================================================
-- ฐานข้อมูลสำหรับโปรเจกต์ E-Book Application (ebook_db)
-- รองรับการนำเข้าผ่าน phpMyAdmin (XAMPP)
-- ============================================================

CREATE DATABASE IF NOT EXISTS ebook_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ebook_db;

-- 1. ตารางผู้ใช้งาน (Users)
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

-- 2. ตารางการยื่นยืนยันตัวตน (KYC Verifications)
CREATE TABLE IF NOT EXISTS kyc_verifications (
    kyc_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
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

-- 3. ตารางนักเขียน (Authors)
CREATE TABLE IF NOT EXISTS authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. ตารางหมวดหมู่หนังสือ (Categories)
CREATE TABLE IF NOT EXISTS categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. ตารางหนังสือ (Books)
CREATE TABLE IF NOT EXISTS books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author_id INT NOT NULL,
    language ENUM('LA', 'TH', 'EN', 'JP', 'CN') DEFAULT 'LA',
    page_count INT DEFAULT 0,
    file_size_bytes BIGINT DEFAULT 0,
    description TEXT,
    cover_image_url VARCHAR(500),
    file_pdf_url VARCHAR(500) NOT NULL,
    uploaded_by INT NOT NULL,
    is_free BOOLEAN DEFAULT FALSE,
    is_hidden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES authors(author_id),
    FOREIGN KEY (uploaded_by) REFERENCES users(user_id)
);

-- 6. ตารางเชื่อม หนังสือ กับ หมวดหมู่ (Book Categories)
CREATE TABLE IF NOT EXISTS book_categories (
    book_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (book_id, category_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);

-- 7. ตารางแพ็กเกจสมาชิก (Packages)
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

-- 8. ตารางการซื้อแพ็กเกจและการโอนเงิน (Subscriptions)
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

-- 9. ตารางหนังสือเล่มโปรด / ชั้นหนังสือส่วนตัว (Bookmarks)
CREATE TABLE IF NOT EXISTS bookmarks (
    bookmark_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_bookmark (user_id, book_id)
);

-- 10. ตารางประวัติการอ่าน (Reading History)
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

-- 11. ตารางประวัติการดาวน์โหลด (Downloads)
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

-- 12. ตารางการแจ้งเตือน (Notifications)
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

-- 13. ตารางบันทึกการทำงานของแอดมิน/พนักงาน (Audit Logs)
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
-- ข้อมูลเริ่มต้น (Seed Initial Data)
-- ============================================================

-- 1. Insert Initial Users
INSERT INTO users (user_id, email, password_hash, first_name, last_name, phone_number, role, status) VALUES
(1, 'admin@gmail.com', '$2a$10$w8T.tK.yvT4N9w6P8L8L.e7pA0rQ1z3m6V5N7P9L3K1J', 'ผู้ดูแล', 'ระบบ (Admin)', '02055551111', 'admin', 'active'),
(2, 'employee@gmail.com', '$2a$10$w8T.tK.yvT4N9w6P8L8L.e7pA0rQ1z3m6V5N7P9L3K1J', 'พนักงาน', 'จัดการคลัง', '02055552222', 'employee', 'active'),
(3, 'user1234@gmail.com', '$2a$10$w8T.tK.yvT4N9w6P8L8L.e7pA0rQ1z3m6V5N7P9L3K1J', 'สมชาย', 'ใจดี', '02055553333', 'user', 'active'),
(4, 'member@gmail.com', '$2a$10$w8T.tK.yvT4N9w6P8L8L.e7pA0rQ1z3m6V5N7P9L3K1J', 'พรีเมี่ยม', 'สมาชิก', '02055554444', 'user', 'active')
ON DUPLICATE KEY UPDATE email=email;

-- 2. Insert Authors
INSERT INTO authors (author_id, name, biography) VALUES
(1, 'Stephen T. Radentz', 'ผู้เขียนหนังสือด้านการพัฒนาตนเองและความสุขในการทำงาน'),
(2, 'Dr. Elias Thorne', 'อาจารย์และนักวิจัยด้านฟิสิกส์ควันตัมและเทคโนโลยีสมัยใหม่'),
(3, 'ดร.จอน วงวิไล', 'ผู้เชี่ยวชาญด้านสังคมศาสตร์และประวัติศาสตร์'),
(4, 'Nageen Prakashan', 'สำนักพิมพ์หนังสือวิทยศาสตร์และคณิตศาสตร์')
ON DUPLICATE KEY UPDATE name=name;

-- 3. Insert Categories
INSERT INTO categories (category_id, name) VALUES
(1, 'ชีวประวัติ / ชีวิต'),
(2, 'วิทยาศาสตร์ / Physics'),
(3, 'เทคโนโลยี / Computer'),
(4, 'ศิลปะ / วรรณคดี'),
(5, 'คณิตศาสตร์')
ON DUPLICATE KEY UPDATE name=name;

-- 4. Insert Packages
INSERT INTO packages (package_id, name, description, price, duration_days, is_for_student, is_active) VALUES
(1, 'Standard Monthly', 'เข้าถึงหนังสืออ่านฟรีและสมาชิกทั่วไป 30 วัน', 49000.00, 30, FALSE, TRUE),
(2, 'Student Special', 'แพ็กเกจพิเศษสำหรับนักเรียน/นักศึกษา ยืนยันผ่าน KYC', 29000.00, 30, TRUE, TRUE),
(3, 'Premium Yearly', 'เข้าถึงหนังสือทุกเล่มในคลังแบบไม่จำกัด 365 วัน', 490000.00, 365, FALSE, TRUE)
ON DUPLICATE KEY UPDATE name=name;

-- 5. Insert Books
INSERT INTO books (book_id, title, author_id, language, page_count, file_size_bytes, description, cover_image_url, file_pdf_url, uploaded_by, is_free, is_hidden) VALUES
(1, 'The Happiness Effect', 1, 'EN', 240, 15400000, 'หนังสือถ่ายทอดเรื่องราวการสร้างความสุขและการมองโลกในแง่ดี', 'assets/happiness_cover.jpg', 'assets/sample_book.pdf', 2, TRUE, FALSE),
(2, 'High School Science', 4, 'LA', 310, 22100000, 'ตำราเรียนวิทยาศาสตร์ระดับมัธยมปลาย ครอบคลุมพื้นฐานฟิสิกส์ เคมี ชีววิทยา', 'assets/science_cover.jpg', 'assets/sample_book.pdf', 2, TRUE, FALSE),
(3, 'Quantum Mechanics', 2, 'EN', 450, 38000000, 'เจาะลึกทฤษฎีควอนตัมและกลศาสตร์สมัยใหม่', 'assets/quantum_cover.jpg', 'assets/sample_book.pdf', 2, FALSE, FALSE),
(4, 'หนังสือสังคมศึกษา', 3, 'LA', 180, 12000000, 'ความรู้เกี่ยวกับสังคม วัฒนธรรม และภูมิศาสตร์', 'assets/social_cover.jpg', 'assets/sample_book.pdf', 2, TRUE, FALSE)
ON DUPLICATE KEY UPDATE title=title;

-- 6. Insert Book Categories
INSERT INTO book_categories (book_id, category_id) VALUES
(1, 1),
(2, 2),
(3, 2),
(3, 3),
(4, 4)
ON DUPLICATE KEY UPDATE book_id=book_id;

-- 7. Insert Subscriptions
INSERT INTO subscriptions (subscription_id, user_id, package_id, amount, slip_image_url, payment_status, approved_by, start_date, end_date) VALUES
(1, 4, 3, 490000.00, 'slips/sample_slip.jpg', 'active', 1, NOW(), DATE_ADD(NOW(), INTERVAL 365 DAY))
ON DUPLICATE KEY UPDATE subscription_id=subscription_id;

-- 8. Insert KYC Verifications
INSERT INTO kyc_verifications (kyc_id, user_id, document_type, document_number, document_image_url, selfie_image_url, is_student, school_name, status) VALUES
(1, 3, 'national_id', '1-1002-34567-89-0', 'kyc/id_card_001.jpg', 'kyc/selfie_001.jpg', FALSE, NULL, 'pending'),
(2, 4, 'student_card', 'STU-99887766', 'kyc/id_card_002.jpg', 'kyc/selfie_002.jpg', TRUE, 'มหาวิทยาลัยแห่งชาติ', 'approved')
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
