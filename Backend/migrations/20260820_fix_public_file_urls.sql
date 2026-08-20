-- =====================================================================
-- Migration: fix public file URLs stored with the container-INTERNAL port 5000
-- Date: 2026-08-20
-- DB:  ebook_db  (Docker MySQL container: ebook-mysql, volume: ebook_mysql-data)
--
-- WHY
--   Some rows were stored with absolute URLs like
--     http://localhost:5000/uploads/pdfs/<file>
--   The Docker host maps 5001 -> container 5000, so the ONLY address a client
--   can reach is http://localhost:5001. Port 5000 is not published, therefore
--   http://localhost:5000/... returns ERR_CONNECTION_REFUSED.
--   Explicit PUBLIC_BASE_URL=http://localhost:5001 now governs new URLs.
--
-- WHAT THIS DOES
--   Only rewrites the host:port inside the stored public file URLs.
--   No schema change, no password change, no other data touched.
--   REPLACE only fires where the old substring exists, so it is idempotent
--   (safe to run more than once).
--
-- Columns with actual 'localhost:5000' rows were verified against the live
-- schema via information_schema before authoring (users.profile_image_url and
-- notifications.target_url had 0 rows and are intentionally not touched).
-- =====================================================================

USE ebook_db;

-- ---------- PREVIEW: counts of broken 5000 URLs BEFORE the fix ----------
SELECT 'books.file_pdf_url'             AS col, COUNT(*) AS n FROM books WHERE file_pdf_url         LIKE '%localhost:5000%'
UNION ALL SELECT 'books.cover_image_url',           COUNT(*)          FROM books                    WHERE cover_image_url LIKE '%localhost:5000%'
UNION ALL SELECT 'subscriptions.slip_image_url',    COUNT(*)          FROM subscriptions            WHERE slip_image_url  LIKE '%localhost:5000%'
UNION ALL SELECT 'kyc_verifications.document_image_url', COUNT(*)     FROM kyc_verifications       WHERE document_image_url LIKE '%localhost:5000%'
UNION ALL SELECT 'kyc_verifications.selfie_image_url',  COUNT(*)      FROM kyc_verifications       WHERE selfie_image_url  LIKE '%localhost:5000%';

-- ---------- FIX: rewrite 5000 -> 5001 in public file URLs ----------
UPDATE books SET file_pdf_url      = REPLACE(file_pdf_url,      'localhost:5000', 'localhost:5001') WHERE file_pdf_url      LIKE '%localhost:5000%';
UPDATE books SET cover_image_url   = REPLACE(cover_image_url,   'localhost:5000', 'localhost:5001') WHERE cover_image_url   LIKE '%localhost:5000%';
UPDATE subscriptions SET slip_image_url = REPLACE(slip_image_url, 'localhost:5000', 'localhost:5001') WHERE slip_image_url LIKE '%localhost:5000%';
UPDATE kyc_verifications SET document_image_url = REPLACE(document_image_url, 'localhost:5000', 'localhost:5001') WHERE document_image_url LIKE '%localhost:5000%';
UPDATE kyc_verifications SET selfie_image_url  = REPLACE(selfie_image_url,  'localhost:5000', 'localhost:5001') WHERE selfie_image_url  LIKE '%localhost:5000%';

-- ---------- VERIFY: remaining broken 5000 URLs AFTER the fix ----------
SELECT 'books.file_pdf_url'             AS col, COUNT(*) AS n FROM books WHERE file_pdf_url         LIKE '%localhost:5000%'
UNION ALL SELECT 'books.cover_image_url',           COUNT(*)          FROM books                    WHERE cover_image_url LIKE '%localhost:5000%'
UNION ALL SELECT 'subscriptions.slip_image_url',    COUNT(*)          FROM subscriptions            WHERE slip_image_url  LIKE '%localhost:5000%'
UNION ALL SELECT 'kyc_verifications.document_image_url', COUNT(*)     FROM kyc_verifications       WHERE document_image_url LIKE '%localhost:5000%'
UNION ALL SELECT 'kyc_verifications.selfie_image_url',  COUNT(*)      FROM kyc_verifications       WHERE selfie_image_url  LIKE '%localhost:5000%';
