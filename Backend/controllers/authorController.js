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

// PUT /api/authors/:id
exports.updateAuthor = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, biography } = req.body;

    await pool.query(
      `UPDATE authors 
       SET name = COALESCE(?, name),
           biography = COALESCE(?, biography)
       WHERE author_id = ?`,
      [name || null, biography !== undefined ? biography : null, id]
    );

    res.json({ success: true, message: 'Author updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/authors/:id
exports.deleteAuthor = async (req, res) => {
  try {
    const { id } = req.params;

    // Set books.author_id to 1 for books that reference this author
    await pool.query('UPDATE books SET author_id = 1 WHERE author_id = ?', [id]);
    await pool.query('DELETE FROM authors WHERE author_id = ?', [id]);

    res.json({ success: true, message: 'Author deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

