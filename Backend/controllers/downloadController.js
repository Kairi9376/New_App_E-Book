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

// POST /api/downloads
exports.recordDownload = async (req, res) => {
  try {
    const { user_id, book_id, device_info } = req.body;
    const ip_address = req.ip || req.connection.remoteAddress;

    if (!user_id || !book_id) {
      return res.status(400).json({ success: false, message: 'user_id and book_id are required' });
    }

    const [result] = await pool.query(
      'INSERT INTO downloads (user_id, book_id, ip_address, device_info) VALUES (?, ?, ?, ?)',
      [user_id, book_id, ip_address, device_info || 'Unknown Device']
    );

    res.status(201).json({ success: true, download_id: result.insertId, message: 'Download recorded' });
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

