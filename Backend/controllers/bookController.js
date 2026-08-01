const { pool } = require('../config/db');

// GET /api/books
exports.getAllBooks = async (req, res) => {
  try {
    const { search, language, category_id, is_free, is_hidden } = req.query;

    let query = `
      SELECT b.*, a.name AS author_name, u.first_name AS uploader_first_name, u.last_name AS uploader_last_name,
             GROUP_CONCAT(c.name SEPARATOR ', ') AS categories
      FROM books b
      LEFT JOIN authors a ON b.author_id = a.author_id
      LEFT JOIN users u ON b.uploaded_by = u.user_id
      LEFT JOIN book_categories bc ON b.book_id = bc.book_id
      LEFT JOIN categories c ON bc.category_id = c.category_id
      WHERE 1=1
    `;
    const params = [];

    if (search) {
      query += ` AND (b.title LIKE ? OR a.name LIKE ? OR b.description LIKE ?)`;
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    if (language) {
      query += ` AND b.language = ?`;
      params.push(language);
    }

    if (category_id) {
      query += ` AND bc.category_id = ?`;
      params.push(category_id);
    }

    if (is_free !== undefined) {
      query += ` AND b.is_free = ?`;
      params.push(is_free === 'true' || is_free === '1' ? 1 : 0);
    }

    if (is_hidden !== undefined) {
      query += ` AND b.is_hidden = ?`;
      params.push(is_hidden === 'true' || is_hidden === '1' ? 1 : 0);
    } else {
      query += ` AND b.is_hidden = FALSE`;
    }

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
             GROUP_CONCAT(c.name SEPARATOR ', ') AS categories
      FROM books b
      LEFT JOIN authors a ON b.author_id = a.author_id
      LEFT JOIN users u ON b.uploaded_by = u.user_id
      LEFT JOIN book_categories bc ON b.book_id = bc.book_id
      LEFT JOIN categories c ON bc.category_id = c.category_id
      WHERE b.book_id = ?
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

// POST /api/books
exports.createBook = async (req, res) => {
  try {
    const {
      title, author_id, language, page_count, file_size_bytes,
      description, cover_image_url, file_pdf_url, uploaded_by,
      is_free, category_ids
    } = req.body;

    if (!title || !author_id || !file_pdf_url || !uploaded_by) {
      return res.status(400).json({ success: false, message: 'Title, author_id, file_pdf_url and uploaded_by are required' });
    }

    const [result] = await pool.query(
      `INSERT INTO books (title, author_id, language, page_count, file_size_bytes, description, cover_image_url, file_pdf_url, uploaded_by, is_free, is_hidden)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, FALSE)`,
      [title, author_id, language || 'LA', page_count || 0, file_size_bytes || 0, description || null, cover_image_url || null, file_pdf_url, uploaded_by, is_free ? 1 : 0]
    );

    const book_id = result.insertId;

    if (Array.isArray(category_ids) && category_ids.length > 0) {
      for (const catId of category_ids) {
        await pool.query('INSERT INTO book_categories (book_id, category_id) VALUES (?, ?)', [book_id, catId]);
      }
    }

    res.status(201).json({ success: true, message: 'Book created successfully', book_id });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/books/:id
exports.updateBook = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, language, page_count, description, cover_image_url, is_free, is_hidden } = req.body;

    await pool.query(
      `UPDATE books 
       SET title = COALESCE(?, title),
           language = COALESCE(?, language),
           page_count = COALESCE(?, page_count),
           description = COALESCE(?, description),
           cover_image_url = COALESCE(?, cover_image_url),
           is_free = COALESCE(?, is_free),
           is_hidden = COALESCE(?, is_hidden)
       WHERE book_id = ?`,
      [title, language, page_count, description, cover_image_url, is_free, is_hidden, id]
    );

    res.json({ success: true, message: 'Book updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/books/:id
exports.deleteBook = async (req, res) => {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM books WHERE book_id = ?', [id]);
    res.json({ success: true, message: 'Book deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
