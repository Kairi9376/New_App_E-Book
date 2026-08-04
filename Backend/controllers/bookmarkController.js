const { pool } = require('../config/db');

// GET /api/bookmarks?user_id=X
exports.getUserBookmarks = async (req, res) => {
  try {
    const { user_id } = req.query;
    if (!user_id) {
      return res.status(400).json({ success: false, message: 'user_id is required' });
    }

    const [rows] = await pool.query(`
      SELECT 
        bm.bookmark_id,
        bm.user_id,
        bm.book_id,
        bm.created_at,
        b.title,
        b.cover_image_url,
        b.file_size_bytes,
        b.file_pdf_url,
        b.page_count,
        b.description,
        b.is_free,
        b.likes_count,
        b.readers_count,
        b.rating,
        a.name AS author_name,
        (
          SELECT GROUP_CONCAT(cat.name SEPARATOR ', ') 
          FROM book_categories bc2 
          JOIN categories cat ON bc2.category_id = cat.category_id 
          WHERE bc2.book_id = b.book_id
        ) AS category_name
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

// POST /api/bookmarks (Toggle or Add Bookmark / Like)
exports.addBookmark = async (req, res) => {
  try {
    const { user_id, book_id } = req.body;
    if (!user_id || !book_id) {
      return res.status(400).json({ success: false, message: 'user_id and book_id are required' });
    }

    // Check if already bookmarked
    const [existing] = await pool.query('SELECT bookmark_id FROM bookmarks WHERE user_id = ? AND book_id = ?', [user_id, book_id]);

    if (existing.length > 0) {
      // Toggle off: remove bookmark and decrement likes_count
      await pool.query('DELETE FROM bookmarks WHERE user_id = ? AND book_id = ?', [user_id, book_id]);
      await pool.query('UPDATE books SET likes_count = GREATEST(0, likes_count - 1) WHERE book_id = ?', [book_id]);
      return res.json({ success: true, isBookmarked: false, message: 'Bookmark removed successfully' });
    } else {
      // Toggle on: add bookmark and increment likes_count
      await pool.query('INSERT INTO bookmarks (user_id, book_id) VALUES (?, ?)', [user_id, book_id]);
      await pool.query('UPDATE books SET likes_count = likes_count + 1 WHERE book_id = ?', [book_id]);
      return res.status(201).json({ success: true, isBookmarked: true, message: 'Bookmark saved successfully' });
    }
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/bookmarks
exports.removeBookmark = async (req, res) => {
  try {
    const { user_id, book_id } = req.body;
    const [result] = await pool.query('DELETE FROM bookmarks WHERE user_id = ? AND book_id = ?', [user_id, book_id]);
    if (result.affectedRows > 0) {
      await pool.query('UPDATE books SET likes_count = GREATEST(0, likes_count - 1) WHERE book_id = ?', [book_id]);
    }
    res.json({ success: true, message: 'Bookmark removed successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
