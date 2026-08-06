const { pool } = require('../config/db');

// GET /api/audit-logs
exports.getAuditLogs = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT al.*, 
             COALESCE(NULLIF(CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, '')), ' '), u.email, 'Admin/Staff') AS user_full_name,
             COALESCE(u.email, '') AS user_email,
             COALESCE(u.role, 'staff') AS user_role
      FROM audit_logs al
      LEFT JOIN users u ON al.user_id = u.user_id
      ORDER BY al.created_at DESC
      LIMIT 200
    `);

    res.json({ success: true, count: rows.length, audit_logs: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Helper internal logger for backend controllers
exports.logAction = async ({ userId, action, details, ipAddress }) => {
  try {
    if (!userId || !action) return;
    await pool.query(
      'INSERT INTO audit_logs (user_id, action, details, ip_address) VALUES (?, ?, ?, ?)',
      [userId, action, details || null, ipAddress || '127.0.0.1']
    );
  } catch (e) {
    console.error('Audit Log Error:', e.message);
  }
};

// POST /api/audit-logs
exports.createAuditLog = async (req, res) => {
  try {
    const { user_id, action, details } = req.body;
    const ip_address = req.ip || req.headers['x-forwarded-for'] || req.connection.remoteAddress || '127.0.0.1';

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
