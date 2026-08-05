const { pool } = require('../config/db');
const { deleteOldFile, isSameFilePath } = require('../utils/fileUtils');

// GET /api/books
exports.getAllBooks = async (req, res) => {
  try {
    const { search, language, category_id, is_free, is_hidden, status, uploaded_by, role } = req.query;

    let query = `
      SELECT b.*, a.name AS author_name, 
             u.first_name AS uploader_first_name, u.last_name AS uploader_last_name,
             r.first_name AS approver_first_name, r.last_name AS approver_last_name,
             GROUP_CONCAT(c.name SEPARATOR ', ') AS categories,
             GROUP_CONCAT(c.category_id SEPARATOR ', ') AS category_ids
      FROM books b
      LEFT JOIN authors a ON b.author_id = a.author_id
      LEFT JOIN users u ON b.uploaded_by = u.user_id
      LEFT JOIN users r ON b.approved_by = r.user_id
      LEFT JOIN book_categories bc ON b.book_id = bc.book_id
      LEFT JOIN categories c ON bc.category_id = c.category_id
      WHERE 1=1
    `;
    const params = [];

    // Filter by Search Keyword
    if (search) {
      query += ` AND (b.title LIKE ? OR a.name LIKE ? OR b.description LIKE ?)`;
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    // Filter by Language
    if (language) {
      query += ` AND b.language = ?`;
      params.push(language);
    }

    // Filter by Category
    if (category_id) {
      query += ` AND bc.category_id = ?`;
      params.push(category_id);
    }

    // Filter by Free access
    if (is_free !== undefined) {
      query += ` AND b.is_free = ?`;
      params.push(is_free === 'true' || is_free === '1' ? 1 : 0);
    }

    // Filter by Employee Uploader
    if (uploaded_by) {
      query += ` AND b.uploaded_by = ?`;
      params.push(uploaded_by);
    }

    // Approval Status & Visibility Logic
    if (status && status !== 'all') {
      query += ` AND b.status = ?`;
      params.push(status);
    } else if (!status && !uploaded_by && role !== 'admin') {
      // 🟢 General App User default: Only books with status = 'approved' AND is_hidden = FALSE
      query += ` AND b.status = 'approved' AND b.is_hidden = FALSE`;
    }

    // Filter by Hidden status if explicitly requested
    if (is_hidden !== undefined) {
      query += ` AND b.is_hidden = ?`;
      params.push(is_hidden === 'true' || is_hidden === '1' ? 1 : 0);
    }

    // Soft delete: ไม่แสดงหนังสือที่ถูกลบแล้ว (is_deleted = TRUE)
    query += ` AND b.is_deleted = FALSE`;

    query += ` GROUP BY b.book_id ORDER BY b.book_id DESC`;

    const [rows] = await pool.query(query, params);
    res.json({ success: true, count: rows.length, books: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/books/:id
exports.getBookById = async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.query(`
      SELECT b.*, a.name AS author_name, a.biography AS author_biography,
             u.first_name AS uploader_first_name, u.last_name AS uploader_last_name,
             r.first_name AS approver_first_name, r.last_name AS approver_last_name,
             GROUP_CONCAT(c.name SEPARATOR ', ') AS categories,
             GROUP_CONCAT(c.category_id SEPARATOR ', ') AS category_ids
      FROM books b
      LEFT JOIN authors a ON b.author_id = a.author_id
      LEFT JOIN users u ON b.uploaded_by = u.user_id
      LEFT JOIN users r ON b.approved_by = r.user_id
      LEFT JOIN book_categories bc ON b.book_id = bc.book_id
      LEFT JOIN categories c ON bc.category_id = c.category_id
      WHERE b.book_id = ? AND b.is_deleted = FALSE
      GROUP BY b.book_id
    `, [id]);

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Book not found' });
    }

    res.json({ success: true, book: rows[0] });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/books (Employee / Staff upload - Default status: 'pending')
exports.createBook = async (req, res) => {
  try {
    const {
      title, author_id, language, page_count, file_size_bytes,
      description, cover_image_url, file_pdf_url, uploaded_by,
      is_free, category_ids, category_id, readers_count, likes_count, status
    } = req.body;

    if (!title) {
      return res.status(400).json({ success: false, message: 'Title is required' });
    }

    const finalAuthorId = author_id || 1;
    const finalUploadedBy = uploaded_by || 2; // Default to Employee (id: 2)
    const finalPdfUrl = file_pdf_url || 'assets/sample_book.pdf';
    const bookStatus = status || 'pending'; // 🟢 Default status is 'pending' requiring Admin approval

    const [result] = await pool.query(
      `INSERT INTO books (title, author_id, language, page_count, file_size_bytes, description, cover_image_url, file_pdf_url, uploaded_by, status, is_free, is_hidden, readers_count, likes_count)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, FALSE, ?, ?)`,
      [title, finalAuthorId, language || 'LA', page_count || 0, file_size_bytes || 0, description || null, cover_image_url || null, finalPdfUrl, finalUploadedBy, bookStatus, is_free ? 1 : 0, readers_count || 0, likes_count || 0]
    );

    const book_id = result.insertId;

    const targetCategories = category_ids || (category_id ? [category_id] : [1]);
    if (Array.isArray(targetCategories) && targetCategories.length > 0) {
      for (const catId of targetCategories) {
        await pool.query('INSERT INTO book_categories (book_id, category_id) VALUES (?, ?)', [book_id, catId]);
      }
    } else {
      await pool.query('INSERT INTO book_categories (book_id, category_id) VALUES (?, 1) ON DUPLICATE KEY UPDATE book_id=book_id', [book_id]);
    }

    res.status(201).json({
      success: true,
      message: 'Book created successfully and pending Admin approval',
      book_id,
      status: bookStatus
    });
  } catch (error) {
    console.error('Create Book Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/books/:id
exports.updateBook = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      title, author_id, language, page_count, description,
      cover_image_url, file_pdf_url, is_free, is_hidden, category_ids,
      category_id, readers_count, likes_count, status, approved_by, rejection_reason
    } = req.body;

    // 1. Fetch current book record to check existing files
    const [existingRows] = await pool.query('SELECT cover_image_url, file_pdf_url FROM books WHERE book_id = ?', [id]);
    if (existingRows.length === 0) {
      return res.status(404).json({ success: false, message: 'Book not found' });
    }
    const currentBook = existingRows[0];

    // 2. Delete old files if cover or PDF changed
    if (cover_image_url && !isSameFilePath(cover_image_url, currentBook.cover_image_url)) {
      deleteOldFile(currentBook.cover_image_url);
    }
    if (file_pdf_url && !isSameFilePath(file_pdf_url, currentBook.file_pdf_url)) {
      deleteOldFile(currentBook.file_pdf_url);
    }

    // 3. Perform database update
    await pool.query(
      `UPDATE books 
       SET title = COALESCE(?, title),
           author_id = COALESCE(?, author_id),
           language = COALESCE(?, language),
           page_count = COALESCE(?, page_count),
           description = COALESCE(?, description),
           cover_image_url = COALESCE(?, cover_image_url),
           file_pdf_url = COALESCE(?, file_pdf_url),
           is_free = COALESCE(?, is_free),
           is_hidden = COALESCE(?, is_hidden),
           readers_count = COALESCE(?, readers_count),
           likes_count = COALESCE(?, likes_count),
           status = COALESCE(?, status),
           approved_by = COALESCE(?, approved_by),
           rejection_reason = COALESCE(?, rejection_reason)
       WHERE book_id = ?`,
      [
        title || null, author_id || null, language || null, page_count || null,
        description || null, cover_image_url || null, file_pdf_url || null,
        is_free !== undefined ? (is_free ? 1 : 0) : null,
        is_hidden !== undefined ? (is_hidden ? 1 : 0) : null,
        readers_count !== undefined ? readers_count : null,
        likes_count !== undefined ? likes_count : null,
        status || null, approved_by || null, rejection_reason || null,
        id
      ]
    );

    // 4. Update book_categories mapping if provided
    const targetCategories = category_ids || (category_id ? [category_id] : null);
    if (targetCategories && Array.isArray(targetCategories) && targetCategories.length > 0) {
      await pool.query('DELETE FROM book_categories WHERE book_id = ?', [id]);
      for (const cId of targetCategories) {
        if (cId) {
          await pool.query('INSERT INTO book_categories (book_id, category_id) VALUES (?, ?)', [id, cId]);
        }
      }
    }

    res.json({ success: true, message: 'Book updated successfully' });
  } catch (error) {
    console.error('Update Book Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/books/:id/status (Admin Approve or Reject Book)
exports.updateBookStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, approved_by, rejection_reason } = req.body;

    if (!['pending', 'approved', 'rejected'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status. Must be pending, approved, or rejected' });
    }

    const finalApprovedBy = approved_by || 1; // Default to Admin ID: 1
    const finalReason = status === 'rejected' ? (rejection_reason || 'เอกสารไม่ตรงตามข้อกำหนด') : null;

    await pool.query(
      `UPDATE books 
       SET status = ?, approved_by = ?, rejection_reason = ?
       WHERE book_id = ?`,
      [status, finalApprovedBy, finalReason, id]
    );

    res.json({
      success: true,
      message: `Book status updated to '${status}' successfully`,
      book_id: id,
      status,
      approved_by: finalApprovedBy,
      rejection_reason: finalReason
    });
  } catch (error) {
    console.error('Update Book Status Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/books/:id/increment-readers
exports.incrementReadersCount = async (req, res) => {
  try {
    const { id } = req.params;
    await pool.query('UPDATE books SET readers_count = readers_count + 1 WHERE book_id = ?', [id]);
    res.json({ success: true, message: 'Readers count incremented' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/books/deleted — ดึงหนังสือที่ soft delete แล้ว (สำหรับ Restore)
exports.getDeletedBooks = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT b.*, a.name AS author_name, u.first_name AS uploader_first_name, u.last_name AS uploader_last_name,
             GROUP_CONCAT(c.name SEPARATOR ', ') AS categories,
             GROUP_CONCAT(c.category_id SEPARATOR ', ') AS category_ids
      FROM books b
      LEFT JOIN authors a ON b.author_id = a.author_id
      LEFT JOIN users u ON b.uploaded_by = u.user_id
      LEFT JOIN book_categories bc ON b.book_id = bc.book_id
      LEFT JOIN categories c ON bc.category_id = c.category_id
      WHERE b.is_deleted = TRUE
      GROUP BY b.book_id
      ORDER BY b.updated_at DESC
    `);

    res.json({ success: true, count: rows.length, books: rows });
  } catch (error) {
    console.error('Get Deleted Books Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/books/:id/restore — กู้คืนหนังสือที่ soft delete แล้ว
exports.restoreBook = async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await pool.query(
      'UPDATE books SET is_deleted = FALSE WHERE book_id = ? AND is_deleted = TRUE',
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Book not found or not deleted' });
    }

    res.json({ success: true, message: 'Book restored successfully' });
  } catch (error) {
    console.error('Restore Book Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/books/:id — Soft Delete (เก็บไฟล์และข้อมูลไว้ กู้คืนได้)
exports.deleteBook = async (req, res) => {
  try {
    const { id } = req.params;

    // Soft delete: ตั้งค่า is_deleted = TRUE (ไม่ลบไฟล์/ข้อมูลจริง)
    const [result] = await pool.query(
      'UPDATE books SET is_deleted = TRUE WHERE book_id = ? AND is_deleted = FALSE',
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Book not found or already deleted' });
    }

    res.json({ success: true, message: 'Book soft-deleted successfully' });
  } catch (error) {
    console.error('Soft Delete Book Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/books/:id/permanent — Hard Delete (สำรองสำหรับ Admin ใช้ในอนาคต)
exports.permanentDeleteBook = async (req, res) => {
  try {
    const { id } = req.params;

    // 1. Fetch current book record to delete physical files
    const [existingRows] = await pool.query('SELECT cover_image_url, file_pdf_url FROM books WHERE book_id = ?', [id]);
    if (existingRows.length > 0) {
      const currentBook = existingRows[0];
      deleteOldFile(currentBook.cover_image_url);
      deleteOldFile(currentBook.file_pdf_url);
    }
    
    // 2. Safely cleanup foreign key dependencies and delete DB record
    await pool.query('DELETE FROM book_categories WHERE book_id = ?', [id]);
    await pool.query('DELETE FROM bookmarks WHERE book_id = ?', [id]);
    await pool.query('DELETE FROM reading_history WHERE book_id = ?', [id]);
    await pool.query('DELETE FROM downloads WHERE book_id = ?', [id]);
    await pool.query('DELETE FROM books WHERE book_id = ?', [id]);

    res.json({ success: true, message: 'Book and associated files permanently deleted' });
  } catch (error) {
    console.error('Permanent Delete Book Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
