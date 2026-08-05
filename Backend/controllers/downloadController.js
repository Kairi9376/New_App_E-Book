const { pool } = require('../config/db');

// GET /api/downloads?user_id=X
exports.getUserDownloads = async (req, res) => {
  try {
    const { user_id } = req.query;
    if (!user_id) {
      return res.status(400).json({ success: false, message: 'user_id is required' });
    }

    const [rows] = await pool.query(`
      SELECT 
        d.download_id,
        d.user_id,
        d.book_id,
        d.ip_address,
        d.device_info,
        d.downloaded_at,
        b.title,
        b.cover_image_url,
        b.file_size_bytes,
        b.file_pdf_url,
        b.page_count,
        b.description,
        b.likes_count,
        b.readers_count,
        b.rating,
        b.is_free,
        b.is_free_download,
        a.name AS author_name,
        (
          SELECT GROUP_CONCAT(cat.name SEPARATOR ', ') 
          FROM book_categories bc2 
          JOIN categories cat ON bc2.category_id = cat.category_id 
          WHERE bc2.book_id = b.book_id
        ) AS category_name
      FROM downloads d
      JOIN books b ON d.book_id = b.book_id
      LEFT JOIN authors a ON b.author_id = a.author_id
      WHERE d.user_id = ?
      ORDER BY d.downloaded_at DESC
    `, [user_id]);

    res.json({ success: true, count: rows.length, downloads: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/downloads/check?user_id=X&book_id=Y — Access Control Check for PDF Download
exports.checkDownloadPermission = async (req, res) => {
  try {
    const { user_id, book_id } = req.query;
    if (!user_id || !book_id) {
      return res.status(400).json({ success: false, message: 'user_id and book_id are required' });
    }

    // 1. Fetch book details
    const [bookRows] = await pool.query('SELECT book_id, title, is_free, is_free_download, is_hidden, status FROM books WHERE book_id = ?', [book_id]);
    if (bookRows.length === 0) {
      return res.status(404).json({ success: false, canDownload: false, message: 'Book not found' });
    }
    const book = bookRows[0];

    // 2. Check 1: If is_free_download is TRUE -> Allow free download for everyone
    if (book.is_free_download === 1 || book.is_free_download === true) {
      return res.json({
        success: true,
        canDownload: true,
        reason: 'free_download',
        message: 'ປຶ້ມເລົ່ມນີ້ເປີດໃຫ້ດາວໂຫຼດຟຣີທຸກຄົນ (Free Download)'
      });
    }

    // 3. Check User role (Admin & Employee can download any book)
    const [userRows] = await pool.query('SELECT role FROM users WHERE user_id = ?', [user_id]);
    if (userRows.length > 0 && ['admin', 'employee'].includes(userRows[0].role)) {
      return res.json({
        success: true,
        canDownload: true,
        reason: 'staff_privilege',
        message: 'ສิทธิ์ແອດມິນ/ພະນັກງານ สามารถດາວໂຫຼດໄດ້'
      });
    }

    // 4. Check 2: If is_free_download is FALSE -> Require active subscription
    const [subRows] = await pool.query(`
      SELECT subscription_id, end_date, payment_status
      FROM subscriptions
      WHERE user_id = ? AND payment_status = 'active'
        AND (end_date IS NULL OR end_date >= NOW())
      ORDER BY end_date DESC LIMIT 1
    `, [user_id]);

    if (subRows.length > 0) {
      return res.json({
        success: true,
        canDownload: true,
        reason: 'active_subscription',
        subscription: subRows[0],
        message: 'ສະມາຊິກພຣີມ່ຽມ สามารถດາວໂຫຼດໄດ້'
      });
    }

    // Access Denied: User has no active subscription and book is not free_download
    return res.status(403).json({
      success: false,
      canDownload: false,
      reason: 'requires_subscription',
      message: 'ປຸ່ມດາວໂຫຼດຖືກລັອກไว้ ກະລຸນາສະໝັກສະມາຊິກເພື່ອດາວໂຫຼດປຶ້ມເລົ່ມນີ້ (Requires Active Subscription)'
    });
  } catch (error) {
    res.status(500).json({ success: false, canDownload: false, message: error.message });
  }
};

// POST /api/downloads (Record Download with Access Control Verification)
exports.recordDownload = async (req, res) => {
  try {
    const { user_id, book_id, device_info } = req.body;
    const ip_address = req.ip || req.connection.remoteAddress;

    if (!user_id || !book_id) {
      return res.status(400).json({ success: false, message: 'user_id and book_id are required' });
    }

    // 1. Fetch book details
    const [bookRows] = await pool.query('SELECT book_id, is_free_download FROM books WHERE book_id = ?', [book_id]);
    if (bookRows.length === 0) {
      return res.status(404).json({ success: false, message: 'Book not found' });
    }
    const book = bookRows[0];

    // 2. Perform Access Control Check if book is NOT free_download
    if (book.is_free_download !== 1 && book.is_free_download !== true) {
      // Check user role (admin/employee bypass)
      const [userRows] = await pool.query('SELECT role FROM users WHERE user_id = ?', [user_id]);
      const isStaff = userRows.length > 0 && ['admin', 'employee'].includes(userRows[0].role);

      if (!isStaff) {
        // Check active subscription
        const [subRows] = await pool.query(`
          SELECT subscription_id FROM subscriptions
          WHERE user_id = ? AND payment_status = 'active'
            AND (end_date IS NULL OR end_date >= NOW())
          LIMIT 1
        `, [user_id]);

        if (subRows.length === 0) {
          return res.status(403).json({
            success: false,
            canDownload: false,
            message: 'ກະລຸນາສະໝັກສະມາຊິກເພື່ອດາວໂຫຼດປຶ້ມເລົ່ມນີ້ (Requires Active Subscription)'
          });
        }
      }
    }

    // 3. Record download entry in database
    const [result] = await pool.query(
      'INSERT INTO downloads (user_id, book_id, ip_address, device_info) VALUES (?, ?, ?, ?)',
      [user_id, book_id, ip_address, device_info || 'Unknown Device']
    );

    res.status(201).json({
      success: true,
      canDownload: true,
      download_id: result.insertId,
      message: 'Download recorded successfully'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/downloads/:download_id
exports.deleteDownload = async (req, res) => {
  try {
    const { download_id } = req.params;
    const { user_id } = req.query;

    let query = 'DELETE FROM downloads WHERE download_id = ?';
    let params = [download_id];

    if (user_id) {
      query += ' AND user_id = ?';
      params.push(user_id);
    }

    const [result] = await pool.query(query, params);

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Download record not found' });
    }

    res.json({ success: true, message: 'Download deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
