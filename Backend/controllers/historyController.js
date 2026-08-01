const { pool } = require('../config/db');

// GET /api/history?user_id=X
exports.getUserReadingHistory = async (req, res) => {
  try {
    const { user_id } = req.query;
    if (!user_id) {
      return res.status(400).json({ success: false, message: 'user_id is required' });
    }

    const [rows] = await pool.query(`
      SELECT rh.*, b.title, b.cover_image_url, b.page_count, a.name AS author_name
      FROM reading_history rh
      JOIN books b ON rh.book_id = b.book_id
      LEFT JOIN authors a ON b.author_id = a.author_id
      WHERE rh.user_id = ?
      ORDER BY rh.last_read_at DESC
    `, [user_id]);

    res.json({ success: true, count: rows.length, history: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/history
exports.saveReadingProgress = async (req, res) => {
  try {
    const { user_id, book_id, last_page_read, progress_percent } = req.body;
    if (!user_id || !book_id) {
      return res.status(400).json({ success: false, message: 'user_id and book_id are required' });
    }

    await pool.query(`
      INSERT INTO reading_history (user_id, book_id, last_page_read, progress_percent)
      VALUES (?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        last_page_read = VALUES(last_page_read),
        progress_percent = VALUES(progress_percent),
        last_read_at = CURRENT_TIMESTAMP
    `, [user_id, book_id, last_page_read || 1, progress_percent || 0.00]);

    res.json({ success: true, message: 'Reading progress saved' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
