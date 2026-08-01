const { pool } = require('../config/db');

// GET /api/packages
exports.getAllPackages = async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM packages WHERE is_active = TRUE ORDER BY price ASC');
    res.json({ success: true, packages: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/packages
exports.createPackage = async (req, res) => {
  try {
    const { name, description, price, duration_days, is_for_student } = req.body;
    if (!name || !price || !duration_days) {
      return res.status(400).json({ success: false, message: 'Name, price, and duration_days are required' });
    }
    const [result] = await pool.query(
      'INSERT INTO packages (name, description, price, duration_days, is_for_student) VALUES (?, ?, ?, ?, ?)',
      [name, description || null, price, duration_days, is_for_student ? 1 : 0]
    );
    res.status(201).json({ success: true, package_id: result.insertId, message: 'Package created' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
