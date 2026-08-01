const { pool } = require('../config/db');

// GET /api/bookmarks?user_id=X
exports.getUserBookmarks = async (req, res) => {
  try {
    const { user_id } = req.query;
    if (!user_id) {
      return res.status(400).json({ success: false, message: 'user_id is required' });
    }

    const [rows] = await pool.query(`
      SELECT bm.*, b.title, b.cover_image_url, b.description, b.is_free, a.name AS author_name
      FROM bookmarks bm
      JOIN books b ON bm.book_id = b.book_id
      LEFT JOIN authors a ON b.author_id = a.author_id
      WHERE bm.user_id = ?
      ORDER BY bm.created_at DESC
    `, [user_id]);

    res.json({ success: true, count: rows.length, bookmarks: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/bookmarks
exports.addBookmark = async (req, res) => {
  try {
    const { user_id, book_id } = req.body;
    if (!user_id || !book_id) {
      return res.status(400).json({ success: false, message: 'user_id and book_id are required' });
    }

    const [result] = await pool.query(
      'INSERT INTO bookmarks (user_id, book_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE created_at = CURRENT_TIMESTAMP',
      [user_id, book_id]
    );

    res.status(201).json({ success: true, message: 'Bookmark saved successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/bookmarks
exports.removeBookmark = async (req, res) => {
  try {
    const { user_id, book_id } = req.body;
    await pool.query('DELETE FROM bookmarks WHERE user_id = ? AND book_id = ?', [user_id, book_id]);
    res.json({ success: true, message: 'Bookmark removed successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
