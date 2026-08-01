const { pool } = require('../config/db');

// GET /api/authors
exports.getAllAuthors = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM authors ORDER BY name ASC');
    res.json({ success: true, authors: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/authors
exports.createAuthor = async (req, res) => {
  try {
    const { name, biography } = req.body;
    if (!name) {
      return res.status(400).json({ success: false, message: 'Author name is required' });
    }
    const [result] = await pool.query(
      'INSERT INTO authors (name, biography) VALUES (?, ?)',
      [name, biography || null]
    );
    res.status(201).json({ success: true, author_id: result.insertId, message: 'Author created' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
