-- ============================================================
-- Repair Lao mojibake (UTF-8 bytes stored as Windows-1252/cp1252).
-- DRAFT - NOT yet executed.  Generated 2026-08-25 by generate_migration.js
-- Each UPDATE fires ONLY when the cell exactly equals the confirmed
-- malformed mojibake string, so it is idempotent and never touches
-- correct (already-Lao) or plain-English text.
-- ============================================================
SET NAMES utf8mb4;
USE ebook_db;

-- ---------- PREVIEW (rows about to be repaired) ----------
SELECT 'authors.name' AS cell, `author_id` AS id, LEFT(`name`,80) AS value
  FROM `authors` WHERE `author_id` = 3;
SELECT 'categories.name' AS cell, `category_id` AS id, LEFT(`name`,80) AS value
  FROM `categories` WHERE `category_id` = 5;
SELECT 'categories.name' AS cell, `category_id` AS id, LEFT(`name`,80) AS value
  FROM `categories` WHERE `category_id` = 4;
SELECT 'categories.name' AS cell, `category_id` AS id, LEFT(`name`,80) AS value
  FROM `categories` WHERE `category_id` = 1;
SELECT 'users.last_name' AS cell, `user_id` AS id, LEFT(`last_name`,80) AS value
  FROM `users` WHERE `user_id` = 1;
SELECT 'users.last_name' AS cell, `user_id` AS id, LEFT(`last_name`,80) AS value
  FROM `users` WHERE `user_id` = 3;
SELECT 'users.first_name' AS cell, `user_id` AS id, LEFT(`first_name`,80) AS value
  FROM `users` WHERE `user_id` = 4;
SELECT 'authors.biography' AS cell, `author_id` AS id, LEFT(`biography`,80) AS value
  FROM `authors` WHERE `author_id` = 1;
SELECT 'authors.biography' AS cell, `author_id` AS id, LEFT(`biography`,80) AS value
  FROM `authors` WHERE `author_id` = 2;
SELECT 'authors.biography' AS cell, `author_id` AS id, LEFT(`biography`,80) AS value
  FROM `authors` WHERE `author_id` = 3;
SELECT 'authors.biography' AS cell, `author_id` AS id, LEFT(`biography`,80) AS value
  FROM `authors` WHERE `author_id` = 4;
SELECT 'books.description' AS cell, `book_id` AS id, LEFT(`description`,80) AS value
  FROM `books` WHERE `book_id` = 1;
SELECT 'books.title' AS cell, `book_id` AS id, LEFT(`title`,80) AS value
  FROM `books` WHERE `book_id` = 2;
SELECT 'books.description' AS cell, `book_id` AS id, LEFT(`description`,80) AS value
  FROM `books` WHERE `book_id` = 2;
SELECT 'books.description' AS cell, `book_id` AS id, LEFT(`description`,80) AS value
  FROM `books` WHERE `book_id` = 3;
SELECT 'books.title' AS cell, `book_id` AS id, LEFT(`title`,80) AS value
  FROM `books` WHERE `book_id` = 4;
SELECT 'books.description' AS cell, `book_id` AS id, LEFT(`description`,80) AS value
  FROM `books` WHERE `book_id` = 4;
SELECT 'books.title' AS cell, `book_id` AS id, LEFT(`title`,80) AS value
  FROM `books` WHERE `book_id` = 5;
SELECT 'books.description' AS cell, `book_id` AS id, LEFT(`description`,80) AS value
  FROM `books` WHERE `book_id` = 5;
SELECT 'categories.name' AS cell, `category_id` AS id, LEFT(`name`,80) AS value
  FROM `categories` WHERE `category_id` = 3;
SELECT 'categories.name' AS cell, `category_id` AS id, LEFT(`name`,80) AS value
  FROM `categories` WHERE `category_id` = 2;
SELECT 'kyc_verifications.school_name' AS cell, `kyc_id` AS id, LEFT(`school_name`,80) AS value
  FROM `kyc_verifications` WHERE `kyc_id` = 2;
SELECT 'packages.description' AS cell, `package_id` AS id, LEFT(`description`,80) AS value
  FROM `packages` WHERE `package_id` = 1;
SELECT 'packages.description' AS cell, `package_id` AS id, LEFT(`description`,80) AS value
  FROM `packages` WHERE `package_id` = 2;
SELECT 'packages.description' AS cell, `package_id` AS id, LEFT(`description`,80) AS value
  FROM `packages` WHERE `package_id` = 3;
SELECT 'users.first_name' AS cell, `user_id` AS id, LEFT(`first_name`,80) AS value
  FROM `users` WHERE `user_id` = 1;
SELECT 'users.first_name' AS cell, `user_id` AS id, LEFT(`first_name`,80) AS value
  FROM `users` WHERE `user_id` = 2;
SELECT 'users.last_name' AS cell, `user_id` AS id, LEFT(`last_name`,80) AS value
  FROM `users` WHERE `user_id` = 2;
SELECT 'users.first_name' AS cell, `user_id` AS id, LEFT(`first_name`,80) AS value
  FROM `users` WHERE `user_id` = 3;
SELECT 'users.last_name' AS cell, `user_id` AS id, LEFT(`last_name`,80) AS value
  FROM `users` WHERE `user_id` = 4;

-- ---------- FIX ----------
UPDATE `authors` SET `name` = 'ດຣ.ຈອນ ວົງວິໄລ'
   WHERE `author_id` = 3 AND `name` = 'àº”àº£.àºˆàº­àº™ àº§àº»àº‡àº§àº´à»„àº¥';
UPDATE `categories` SET `name` = 'ຄະນິດສາດ'
   WHERE `category_id` = 5 AND `name` = 'àº„àº°àº™àº´àº”àºªàº²àº”';
UPDATE `categories` SET `name` = 'ສິນລະປະ / ວັນນະຄະດີ'
   WHERE `category_id` = 4 AND `name` = 'àºªàº´àº™àº¥àº°àº›àº° / àº§àº±àº™àº™àº°àº„àº°àº”àºµ';
UPDATE `categories` SET `name` = 'ຊີວະປະຫວັດ / ຊີວິດ'
   WHERE `category_id` = 1 AND `name` = 'àºŠàºµàº§àº°àº›àº°àº«àº§àº±àº” / àºŠàºµàº§àº´àº”';
UPDATE `users` SET `last_name` = 'ລະບົບ (Admin)'
   WHERE `user_id` = 1 AND `last_name` = 'àº¥àº°àºšàº»àºš (Admin)';
UPDATE `users` SET `last_name` = 'ໃຈດີ'
   WHERE `user_id` = 3 AND `last_name` = 'à»ƒàºˆàº”àºµ';
UPDATE `users` SET `first_name` = 'ພຣີມ່ຽມ'
   WHERE `user_id` = 4 AND `first_name` = 'àºžàº£àºµàº¡à»ˆàº½àº¡';
UPDATE `authors` SET `biography` = 'ຜູ້ຂຽນປຶ້ມດ້ານການພັດທະນາຕົນເອງ ແລະ ຄວາມສຸກໃນການເຮັດວຽກ'
   WHERE `author_id` = 1 AND `biography` = 'àºœàº¹à»‰àº‚àº½àº™àº›àº¶à»‰àº¡àº”à»‰àº²àº™àºàº²àº™àºžàº±àº”àº—àº°àº™àº²àº•àº»àº™à»€àº­àº‡ à»àº¥àº° àº„àº§àº²àº¡àºªàº¸àºà»ƒàº™àºàº²àº™à»€àº®àº±àº”àº§àº½àº';
UPDATE `authors` SET `biography` = 'ອາຈານ ແລະ ນັກວິໄຈດ້ານຟິຊິກຄວອນຕຳ ແລະ ເຕັກໂນໂລຊີສະໄໝໃໝ່'
   WHERE `author_id` = 2 AND `biography` = 'àº­àº²àºˆàº²àº™ à»àº¥àº° àº™àº±àºàº§àº´à»„àºˆàº”à»‰àº²àº™àºŸàº´àºŠàº´àºàº„àº§àº­àº™àº•àº³ à»àº¥àº° à»€àº•àº±àºà»‚àº™à»‚àº¥àºŠàºµàºªàº°à»„à»à»ƒà»à»ˆ';
UPDATE `authors` SET `biography` = 'ຜູ້ຊ່ຽວຊານດ້ານສັງຄົມສາດ ແລະ ປະຫວັດສາດ'
   WHERE `author_id` = 3 AND `biography` = 'àºœàº¹à»‰àºŠà»ˆàº½àº§àºŠàº²àº™àº”à»‰àº²àº™àºªàº±àº‡àº„àº»àº¡àºªàº²àº” à»àº¥àº° àº›àº°àº«àº§àº±àº”àºªàº²àº”';
UPDATE `authors` SET `biography` = 'ສຳນັກພິມປຶ້ມວິທະຍາສາດ ແລະ ຄະນິດສາດ'
   WHERE `author_id` = 4 AND `biography` = 'àºªàº³àº™àº±àºàºžàº´àº¡àº›àº¶à»‰àº¡àº§àº´àº—àº°àºàº²àºªàº²àº” à»àº¥àº° àº„àº°àº™àº´àº”àºªàº²àº”';
UPDATE `books` SET `description` = 'ປຶ້ມຖ່າຍທອດເລື່ອງราวການສ້າງຄວາມສຸກ ແລະ ການມອງໂລກໃນແງ່ດີ'
   WHERE `book_id` = 1 AND `description` = 'àº›àº¶à»‰àº¡àº–à»ˆàº²àºàº—àº­àº”à»€àº¥àº·à»ˆàº­àº‡à¸£à¸²à¸§àºàº²àº™àºªà»‰àº²àº‡àº„àº§àº²àº¡àºªàº¸àº à»àº¥àº° àºàº²àº™àº¡àº­àº‡à»‚àº¥àºà»ƒàº™à»àº‡à»ˆàº”àºµ';
UPDATE `books` SET `title` = 'High School Science (ວິທະຍາສາດ)'
   WHERE `book_id` = 2 AND `title` = 'High School Science (àº§àº´àº—àº°àºàº²àºªàº²àº”)';
UPDATE `books` SET `description` = 'ຕຳລາຮຽນວິທະຍາສາດລະດັບມັດທະຍົມປາຍ ຄອບຄຸມພື້ນຖານຟິຊິກ ເຄມີ ຊີວະວິທະຍາ'
   WHERE `book_id` = 2 AND `description` = 'àº•àº³àº¥àº²àº®àº½àº™àº§àº´àº—àº°àºàº²àºªàº²àº”àº¥àº°àº”àº±àºšàº¡àº±àº”àº—àº°àºàº»àº¡àº›àº²àº àº„àº­àºšàº„àº¸àº¡àºžàº·à»‰àº™àº–àº²àº™àºŸàº´àºŠàº´àº à»€àº„àº¡àºµ àºŠàºµàº§àº°àº§àº´àº—àº°àºàº²';
UPDATE `books` SET `description` = 'ເຈາະລຶກທິດສະດີຄວອນຕຳ ແລະ ກົນລະສາດສະໄໝໃໝ່'
   WHERE `book_id` = 3 AND `description` = 'à»€àºˆàº²àº°àº¥àº¶àºàº—àº´àº”àºªàº°àº”àºµàº„àº§àº­àº™àº•àº³ à»àº¥àº° àºàº»àº™àº¥àº°àºªàº²àº”àºªàº°à»„à»à»ƒà»à»ˆ';
UPDATE `books` SET `title` = 'ປຶ້ມສັງຄົມສຶກສາ'
   WHERE `book_id` = 4 AND `title` = 'àº›àº¶à»‰àº¡àºªàº±àº‡àº„àº»àº¡àºªàº¶àºàºªàº²';
UPDATE `books` SET `description` = 'ຄວາມຮູ້ກ່ຽວກັບສັງຄົມ ວັດທະນະທຳ ແລະ ພູມສາດ'
   WHERE `book_id` = 4 AND `description` = 'àº„àº§àº²àº¡àº®àº¹à»‰àºà»ˆàº½àº§àºàº±àºšàºªàº±àº‡àº„àº»àº¡ àº§àº±àº”àº—àº°àº™àº°àº—àº³ à»àº¥àº° àºžàº¹àº¡àºªàº²àº”';
UPDATE `books` SET `title` = 'Advances in Physics (ລໍຖ້າອະນຸມັດ)'
   WHERE `book_id` = 5 AND `title` = 'Advances in Physics (àº¥à»àº–à»‰àº²àº­àº°àº™àº¸àº¡àº±àº”)';
UPDATE `books` SET `description` = 'ຕຳລາຟິຊິກຂັ້ນສູງ ສຳລັບນັກຮຽນ ແລະ ນັກວິໄຈ'
   WHERE `book_id` = 5 AND `description` = 'àº•àº³àº¥àº²àºŸàº´àºŠàº´àºàº‚àº±à»‰àº™àºªàº¹àº‡ àºªàº³àº¥àº±àºšàº™àº±àºàº®àº½àº™ à»àº¥àº° àº™àº±àºàº§àº´à»„àºˆ';
UPDATE `categories` SET `name` = 'ເຕັກໂນໂລຊີ / Computer'
   WHERE `category_id` = 3 AND `name` = 'à»€àº•àº±àºà»‚àº™à»‚àº¥àºŠàºµ / Computer';
UPDATE `categories` SET `name` = 'ວິທະຍາສາດ / Physics'
   WHERE `category_id` = 2 AND `name` = 'àº§àº´àº—àº°àºàº²àºªàº²àº” / Physics';
UPDATE `kyc_verifications` SET `school_name` = 'ມະຫາວິທະຍາໄລແຫ່ງຊາດ'
   WHERE `kyc_id` = 2 AND `school_name` = 'àº¡àº°àº«àº²àº§àº´àº—àº°àºàº²à»„àº¥à»àº«à»ˆàº‡àºŠàº²àº”';
UPDATE `packages` SET `description` = 'ເຂົ້າເຖິງປຶ້ມອ່ານຟຣີ ແລະ ສະມາຊິກທົ່ວໄປ 30 ວັນ'
   WHERE `package_id` = 1 AND `description` = 'à»€àº‚àº»à»‰àº²à»€àº–àº´àº‡àº›àº¶à»‰àº¡àº­à»ˆàº²àº™àºŸàº£àºµ à»àº¥àº° àºªàº°àº¡àº²àºŠàº´àºàº—àº»à»ˆàº§à»„àº› 30 àº§àº±àº™';
UPDATE `packages` SET `description` = 'ແພັກເກດພິເສດสำหรับນັກຮຽນ/ນັກສຶກສາ ຢືນຢັນຜ່ານ KYC'
   WHERE `package_id` = 2 AND `description` = 'à»àºžàº±àºà»€àºàº”àºžàº´à»€àºªàº”à¸ªà¸³à¸«à¸£à¸±à¸šàº™àº±àºàº®àº½àº™/àº™àº±àºàºªàº¶àºàºªàº² àº¢àº·àº™àº¢àº±àº™àºœà»ˆàº²àº™ KYC';
UPDATE `packages` SET `description` = 'ເຂົ້າເຖິງປຶ້ມທຸກເລົ່ມໃນຄັງແບບບໍ່ຈຳກັດ 365 ວັນ'
   WHERE `package_id` = 3 AND `description` = 'à»€àº‚àº»à»‰àº²à»€àº–àº´àº‡àº›àº¶à»‰àº¡àº—àº¸àºà»€àº¥àº»à»ˆàº¡à»ƒàº™àº„àº±àº‡à»àºšàºšàºšà»à»ˆàºˆàº³àºàº±àº” 365 àº§àº±àº™';
UPDATE `users` SET `first_name` = 'ຜູ້ດູແລ'
   WHERE `user_id` = 1 AND `first_name` = 'àºœàº¹à»‰àº”àº¹à»àº¥';
UPDATE `users` SET `first_name` = 'ພະນັກງານ'
   WHERE `user_id` = 2 AND `first_name` = 'àºžàº°àº™àº±àºàº‡àº²àº™';
UPDATE `users` SET `last_name` = 'ຈັດການຄັງ'
   WHERE `user_id` = 2 AND `last_name` = 'àºˆàº±àº”àºàº²àº™àº„àº±àº‡';
UPDATE `users` SET `first_name` = 'ສົມຊາຍ'
   WHERE `user_id` = 3 AND `first_name` = 'àºªàº»àº¡àºŠàº²àº';
UPDATE `users` SET `last_name` = 'ສະມາຊິກ'
   WHERE `user_id` = 4 AND `last_name` = 'àºªàº°àº¡àº²àºŠàº´àº';

-- ---------- VERIFY (remaining mojibake = 0 expected) ----------
-- authors.name pk=3
SELECT COUNT(*) AS still_broken FROM `authors` WHERE `author_id` = 3 AND `name` = 'àº”àº£.àºˆàº­àº™ àº§àº»àº‡àº§àº´à»„àº¥';
-- categories.name pk=5
SELECT COUNT(*) AS still_broken FROM `categories` WHERE `category_id` = 5 AND `name` = 'àº„àº°àº™àº´àº”àºªàº²àº”';
-- categories.name pk=4
SELECT COUNT(*) AS still_broken FROM `categories` WHERE `category_id` = 4 AND `name` = 'àºªàº´àº™àº¥àº°àº›àº° / àº§àº±àº™àº™àº°àº„àº°àº”àºµ';
-- categories.name pk=1
SELECT COUNT(*) AS still_broken FROM `categories` WHERE `category_id` = 1 AND `name` = 'àºŠàºµàº§àº°àº›àº°àº«àº§àº±àº” / àºŠàºµàº§àº´àº”';
-- users.last_name pk=1
SELECT COUNT(*) AS still_broken FROM `users` WHERE `user_id` = 1 AND `last_name` = 'àº¥àº°àºšàº»àºš (Admin)';
-- users.last_name pk=3
SELECT COUNT(*) AS still_broken FROM `users` WHERE `user_id` = 3 AND `last_name` = 'à»ƒàºˆàº”àºµ';
-- users.first_name pk=4
SELECT COUNT(*) AS still_broken FROM `users` WHERE `user_id` = 4 AND `first_name` = 'àºžàº£àºµàº¡à»ˆàº½àº¡';
-- authors.biography pk=1
SELECT COUNT(*) AS still_broken FROM `authors` WHERE `author_id` = 1 AND `biography` = 'àºœàº¹à»‰àº‚àº½àº™àº›àº¶à»‰àº¡àº”à»‰àº²àº™àºàº²àº™àºžàº±àº”àº—àº°àº™àº²àº•àº»àº™à»€àº­àº‡ à»àº¥àº° àº„àº§àº²àº¡àºªàº¸àºà»ƒàº™àºàº²àº™à»€àº®àº±àº”àº§àº½àº';
-- authors.biography pk=2
SELECT COUNT(*) AS still_broken FROM `authors` WHERE `author_id` = 2 AND `biography` = 'àº­àº²àºˆàº²àº™ à»àº¥àº° àº™àº±àºàº§àº´à»„àºˆàº”à»‰àº²àº™àºŸàº´àºŠàº´àºàº„àº§àº­àº™àº•àº³ à»àº¥àº° à»€àº•àº±àºà»‚àº™à»‚àº¥àºŠàºµàºªàº°à»„à»à»ƒà»à»ˆ';
-- authors.biography pk=3
SELECT COUNT(*) AS still_broken FROM `authors` WHERE `author_id` = 3 AND `biography` = 'àºœàº¹à»‰àºŠà»ˆàº½àº§àºŠàº²àº™àº”à»‰àº²àº™àºªàº±àº‡àº„àº»àº¡àºªàº²àº” à»àº¥àº° àº›àº°àº«àº§àº±àº”àºªàº²àº”';
-- authors.biography pk=4
SELECT COUNT(*) AS still_broken FROM `authors` WHERE `author_id` = 4 AND `biography` = 'àºªàº³àº™àº±àºàºžàº´àº¡àº›àº¶à»‰àº¡àº§àº´àº—àº°àºàº²àºªàº²àº” à»àº¥àº° àº„àº°àº™àº´àº”àºªàº²àº”';
-- books.description pk=1
SELECT COUNT(*) AS still_broken FROM `books` WHERE `book_id` = 1 AND `description` = 'àº›àº¶à»‰àº¡àº–à»ˆàº²àºàº—àº­àº”à»€àº¥àº·à»ˆàº­àº‡à¸£à¸²à¸§àºàº²àº™àºªà»‰àº²àº‡àº„àº§àº²àº¡àºªàº¸àº à»àº¥àº° àºàº²àº™àº¡àº­àº‡à»‚àº¥àºà»ƒàº™à»àº‡à»ˆàº”àºµ';
-- books.title pk=2
SELECT COUNT(*) AS still_broken FROM `books` WHERE `book_id` = 2 AND `title` = 'High School Science (àº§àº´àº—àº°àºàº²àºªàº²àº”)';
-- books.description pk=2
SELECT COUNT(*) AS still_broken FROM `books` WHERE `book_id` = 2 AND `description` = 'àº•àº³àº¥àº²àº®àº½àº™àº§àº´àº—àº°àºàº²àºªàº²àº”àº¥àº°àº”àº±àºšàº¡àº±àº”àº—àº°àºàº»àº¡àº›àº²àº àº„àº­àºšàº„àº¸àº¡àºžàº·à»‰àº™àº–àº²àº™àºŸàº´àºŠàº´àº à»€àº„àº¡àºµ àºŠàºµàº§àº°àº§àº´àº—àº°àºàº²';
-- books.description pk=3
SELECT COUNT(*) AS still_broken FROM `books` WHERE `book_id` = 3 AND `description` = 'à»€àºˆàº²àº°àº¥àº¶àºàº—àº´àº”àºªàº°àº”àºµàº„àº§àº­àº™àº•àº³ à»àº¥àº° àºàº»àº™àº¥àº°àºªàº²àº”àºªàº°à»„à»à»ƒà»à»ˆ';
-- books.title pk=4
SELECT COUNT(*) AS still_broken FROM `books` WHERE `book_id` = 4 AND `title` = 'àº›àº¶à»‰àº¡àºªàº±àº‡àº„àº»àº¡àºªàº¶àºàºªàº²';
-- books.description pk=4
SELECT COUNT(*) AS still_broken FROM `books` WHERE `book_id` = 4 AND `description` = 'àº„àº§àº²àº¡àº®àº¹à»‰àºà»ˆàº½àº§àºàº±àºšàºªàº±àº‡àº„àº»àº¡ àº§àº±àº”àº—àº°àº™àº°àº—àº³ à»àº¥àº° àºžàº¹àº¡àºªàº²àº”';
-- books.title pk=5
SELECT COUNT(*) AS still_broken FROM `books` WHERE `book_id` = 5 AND `title` = 'Advances in Physics (àº¥à»àº–à»‰àº²àº­àº°àº™àº¸àº¡àº±àº”)';
-- books.description pk=5
SELECT COUNT(*) AS still_broken FROM `books` WHERE `book_id` = 5 AND `description` = 'àº•àº³àº¥àº²àºŸàº´àºŠàº´àºàº‚àº±à»‰àº™àºªàº¹àº‡ àºªàº³àº¥àº±àºšàº™àº±àºàº®àº½àº™ à»àº¥àº° àº™àº±àºàº§àº´à»„àºˆ';
-- categories.name pk=3
SELECT COUNT(*) AS still_broken FROM `categories` WHERE `category_id` = 3 AND `name` = 'à»€àº•àº±àºà»‚àº™à»‚àº¥àºŠàºµ / Computer';
-- categories.name pk=2
SELECT COUNT(*) AS still_broken FROM `categories` WHERE `category_id` = 2 AND `name` = 'àº§àº´àº—àº°àºàº²àºªàº²àº” / Physics';
-- kyc_verifications.school_name pk=2
SELECT COUNT(*) AS still_broken FROM `kyc_verifications` WHERE `kyc_id` = 2 AND `school_name` = 'àº¡àº°àº«àº²àº§àº´àº—àº°àºàº²à»„àº¥à»àº«à»ˆàº‡àºŠàº²àº”';
-- packages.description pk=1
SELECT COUNT(*) AS still_broken FROM `packages` WHERE `package_id` = 1 AND `description` = 'à»€àº‚àº»à»‰àº²à»€àº–àº´àº‡àº›àº¶à»‰àº¡àº­à»ˆàº²àº™àºŸàº£àºµ à»àº¥àº° àºªàº°àº¡àº²àºŠàº´àºàº—àº»à»ˆàº§à»„àº› 30 àº§àº±àº™';
-- packages.description pk=2
SELECT COUNT(*) AS still_broken FROM `packages` WHERE `package_id` = 2 AND `description` = 'à»àºžàº±àºà»€àºàº”àºžàº´à»€àºªàº”à¸ªà¸³à¸«à¸£à¸±à¸šàº™àº±àºàº®àº½àº™/àº™àº±àºàºªàº¶àºàºªàº² àº¢àº·àº™àº¢àº±àº™àºœà»ˆàº²àº™ KYC';
-- packages.description pk=3
SELECT COUNT(*) AS still_broken FROM `packages` WHERE `package_id` = 3 AND `description` = 'à»€àº‚àº»à»‰àº²à»€àº–àº´àº‡àº›àº¶à»‰àº¡àº—àº¸àºà»€àº¥àº»à»ˆàº¡à»ƒàº™àº„àº±àº‡à»àºšàºšàºšà»à»ˆàºˆàº³àºàº±àº” 365 àº§àº±àº™';
-- users.first_name pk=1
SELECT COUNT(*) AS still_broken FROM `users` WHERE `user_id` = 1 AND `first_name` = 'àºœàº¹à»‰àº”àº¹à»àº¥';
-- users.first_name pk=2
SELECT COUNT(*) AS still_broken FROM `users` WHERE `user_id` = 2 AND `first_name` = 'àºžàº°àº™àº±àºàº‡àº²àº™';
-- users.last_name pk=2
SELECT COUNT(*) AS still_broken FROM `users` WHERE `user_id` = 2 AND `last_name` = 'àºˆàº±àº”àºàº²àº™àº„àº±àº‡';
-- users.first_name pk=3
SELECT COUNT(*) AS still_broken FROM `users` WHERE `user_id` = 3 AND `first_name` = 'àºªàº»àº¡àºŠàº²àº';
-- users.last_name pk=4
SELECT COUNT(*) AS still_broken FROM `users` WHERE `user_id` = 4 AND `last_name` = 'àºªàº°àº¡àº²àºŠàº´àº';

-- -------- Manual review needed (no authoritative seed) --------
--   kyc_verifications.full_name pk=3 (no seed literal)