const { pool } = require('../config/db');

// GET /api/audit-logs
exports.getAuditLogs = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT al.*, u.first_name, u.last_name, u.email, u.role
      FROM audit_logs al
      JOIN users u ON al.user_id = u.user_id
      ORDER BY al.created_at DESC
      LIMIT 100
    `);

    res.json({ success: true, count: rows.length, audit_logs: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/audit-logs
exports.createAuditLog = async (req, res) => {
  try {
    const { user_id, action, details } = req.body;
    const ip_address = req.ip || req.connection.remoteAddress;

    if (!user_id || !action) {
      return res.status(400).json({ success: false, message: 'user_id and action are required' });
    }

    const [result] = await pool.query(
      'INSERT INTO audit_logs (user_id, action, details, ip_address) VALUES (?, ?, ?, ?)',
      [user_id, action, details || null, ip_address]
    );

    res.status(201).json({ success: true, log_id: result.insertId });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
