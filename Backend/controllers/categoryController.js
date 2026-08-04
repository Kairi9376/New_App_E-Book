const { pool } = require('../config/db');

// GET /api/categories
exports.getAllCategories = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM categories ORDER BY name ASC');
    res.json({ success: true, categories: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/categories
exports.createCategory = async (req, res) => {
  try {
    const { name } = req.body;
    if (!name) {
      return res.status(400).json({ success: false, message: 'Category name is required' });
    }
    const [result] = await pool.query('INSERT INTO categories (name) VALUES (?)', [name]);
    res.status(201).json({ success: true, category_id: result.insertId, message: 'Category created' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/categories/:id
exports.updateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;

    if (!name) {
      return res.status(400).json({ success: false, message: 'Category name is required' });
    }

    // ตรวจสอบ category มีอยู่หรือไม่
    const [existingRows] = await pool.query('SELECT category_id FROM categories WHERE category_id = ?', [id]);
    if (existingRows.length === 0) {
      return res.status(404).json({ success: false, message: 'Category not found' });
    }

    // ตรวจสอบ duplicate name (ยกเว้นตัวเอง)
    const [dupRows] = await pool.query(
      'SELECT category_id FROM categories WHERE name = ? AND category_id != ?',
      [name, id]
    );
    if (dupRows.length > 0) {
      return res.status(400).json({ success: false, message: 'Category name already exists' });
    }

    await pool.query('UPDATE categories SET name = ? WHERE category_id = ?', [name, id]);

    res.json({ success: true, message: 'Category updated successfully' });
  } catch (error) {
    console.error('Update Category Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/categories/:id
exports.deleteCategory = async (req, res) => {
  try {
    const { id } = req.params;

    // ตรวจสอบ category มีอยู่หรือไม่
    const [existingRows] = await pool.query('SELECT category_id FROM categories WHERE category_id = ?', [id]);
    if (existingRows.length === 0) {
      return res.status(404).json({ success: false, message: 'Category not found' });
    }

    // ลบ category — book_categories มี ON DELETE CASCADE จะลบ mapping อัตโนมัติ (ไม่ลบหนังสือ)
    await pool.query('DELETE FROM categories WHERE category_id = ?', [id]);

    res.json({ success: true, message: 'Category deleted successfully' });
  } catch (error) {
    console.error('Delete Category Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
