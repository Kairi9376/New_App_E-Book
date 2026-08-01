const { pool } = require('../config/db');

// GET /api/subscriptions
exports.getAllSubscriptions = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT s.*, u.first_name, u.last_name, u.email, p.name AS package_name, p.duration_days,
             a.first_name AS approver_first_name, a.last_name AS approver_last_name
      FROM subscriptions s
      JOIN users u ON s.user_id = u.user_id
      JOIN packages p ON s.package_id = p.package_id
      LEFT JOIN users a ON s.approved_by = a.user_id
      ORDER BY s.created_at DESC
    `);
    res.json({ success: true, count: rows.length, subscriptions: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/subscriptions
exports.createSubscription = async (req, res) => {
  try {
    const { user_id, package_id, amount, slip_image_url, payment_method } = req.body;

    if (!user_id || !package_id || !amount || !slip_image_url) {
      return res.status(400).json({ success: false, message: 'Please provide required subscription payment details' });
    }

    const [result] = await pool.query(
      `INSERT INTO subscriptions (user_id, package_id, amount, slip_image_url, payment_method, payment_status)
       VALUES (?, ?, ?, ?, ?, 'pending')`,
      [user_id, package_id, amount, slip_image_url, payment_method || 'bank_transfer']
    );

    res.status(201).json({ success: true, subscription_id: result.insertId, message: 'Subscription request submitted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/subscriptions/:id/status
exports.updateSubscriptionStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { payment_status, approved_by, rejected_reason } = req.body;

    let startDate = null;
    let endDate = null;

    if (payment_status === 'active') {
      const [subRows] = await pool.query('SELECT package_id FROM subscriptions WHERE subscription_id = ?', [id]);
      if (subRows.length > 0) {
        const [pkgRows] = await pool.query('SELECT duration_days FROM packages WHERE package_id = ?', [subRows[0].package_id]);
        const durationDays = pkgRows[0] ? pkgRows[0].duration_days : 30;
        startDate = new Date();
        endDate = new Date();
        endDate.setDate(endDate.getDate() + durationDays);
      }
    }

    await pool.query(
      `UPDATE subscriptions
       SET payment_status = ?, approved_by = ?, rejected_reason = ?,
           start_date = COALESCE(?, start_date), end_date = COALESCE(?, end_date)
       WHERE subscription_id = ?`,
      [payment_status, approved_by || null, rejected_reason || null, startDate, endDate, id]
    );

    res.json({ success: true, message: `Subscription status updated to ${payment_status}` });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
