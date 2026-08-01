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
