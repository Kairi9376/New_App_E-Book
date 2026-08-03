const { pool } = require('../config/db');
const { deleteOldFile } = require('../utils/fileUtils');

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

// PUT /api/users/:id (Update User Profile & Avatar)
exports.updateUserProfile = async (req, res) => {
  try {
    const { id } = req.params;
    const { first_name, last_name, phone_number, birth_date, gender, profile_image_url } = req.body;

    const [existingRows] = await pool.query('SELECT profile_image_url FROM users WHERE user_id = ?', [id]);
    if (existingRows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const currentProfileImage = existingRows[0].profile_image_url;

    // Delete old profile picture if new profile_image_url is provided and different
    if (profile_image_url && profile_image_url !== currentProfileImage) {
      deleteOldFile(currentProfileImage);
    }

    await pool.query(
      `UPDATE users 
       SET first_name = COALESCE(?, first_name),
           last_name = COALESCE(?, last_name),
           phone_number = COALESCE(?, phone_number),
           birth_date = COALESCE(?, birth_date),
           gender = COALESCE(?, gender),
           profile_image_url = COALESCE(?, profile_image_url)
       WHERE user_id = ?`,
      [first_name || null, last_name || null, phone_number || null, birth_date || null, gender || null, profile_image_url || null, id]
    );

    res.json({ success: true, message: 'User profile updated successfully' });
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
