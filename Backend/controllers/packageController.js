const { pool } = require('../config/db');

// GET /api/packages
exports.getAllPackages = async (req, res) => {
  try {
    const showAll = req.query.all === 'true';
    const query = showAll
      ? 'SELECT * FROM packages ORDER BY package_id ASC'
      : 'SELECT * FROM packages WHERE is_active = TRUE ORDER BY price ASC';
    const [rows] = await pool.query(query);
    res.json({ success: true, packages: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/packages
exports.createPackage = async (req, res) => {
  try {
    const { name, description, price, duration_days, is_for_student, is_active } = req.body;
    if (!name || !price || !duration_days) {
      return res.status(400).json({ success: false, message: 'Name, price, and duration_days are required' });
    }
    const activeVal = is_active === false || is_active === 0 ? 0 : 1;
    const [result] = await pool.query(
      'INSERT INTO packages (name, description, price, duration_days, is_for_student, is_active) VALUES (?, ?, ?, ?, ?, ?)',
      [name, description || null, price, duration_days, is_for_student ? 1 : 0, activeVal]
    );
    res.status(201).json({ success: true, package_id: result.insertId, message: 'Package created' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/packages/:id/status
exports.updatePackageStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { is_active } = req.body;
    const activeVal = (is_active === true || is_active === 1 || is_active === '1') ? 1 : 0;
    
    await pool.query('UPDATE packages SET is_active = ? WHERE package_id = ?', [activeVal, id]);
    res.json({ success: true, message: 'Package status updated' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/packages/:id
exports.updatePackage = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, price, duration_days, is_for_student, is_active } = req.body;

    await pool.query(
      `UPDATE packages 
       SET name = COALESCE(?, name),
           description = COALESCE(?, description),
           price = COALESCE(?, price),
           duration_days = COALESCE(?, duration_days),
           is_for_student = COALESCE(?, is_for_student),
           is_active = COALESCE(?, is_active)
       WHERE package_id = ?`,
      [
        name || null,
        description || null,
        price || null,
        duration_days || null,
        is_for_student !== undefined ? (is_for_student ? 1 : 0) : null,
        is_active !== undefined ? (is_active ? 1 : 0) : null,
        id,
      ]
    );

    res.json({ success: true, message: 'Package updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
