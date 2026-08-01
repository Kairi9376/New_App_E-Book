const { pool } = require('../config/db');

// GET /api/users
exports.getAllUsers = async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT user_id, email, first_name, last_name, phone_number, birth_date, gender, profile_image_url, role, status, created_at FROM users ORDER BY user_id DESC'
    );
    res.json({ success: true, count: rows.length, users: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/users/:id
exports.getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await pool.query(
      'SELECT user_id, email, first_name, last_name, phone_number, birth_date, gender, profile_image_url, role, status, created_at FROM users WHERE user_id = ?',
      [id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.json({ success: true, user: rows[0] });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/users/:id/status
exports.updateUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, suspended_reason } = req.body;

    await pool.query(
      'UPDATE users SET status = ?, suspended_reason = ? WHERE user_id = ?',
      [status, suspended_reason || null, id]
    );

    res.json({ success: true, message: `User status updated to ${status}` });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
