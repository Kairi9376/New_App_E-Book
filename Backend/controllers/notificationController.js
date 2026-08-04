const { pool } = require('../config/db');

// Helper to insert a notification into DB
exports.createNotification = async ({ userId, title, message, type = 'system', targetUrl = null }) => {
  try {
    await pool.query(
      `INSERT INTO notifications (user_id, title, message, type, is_read, target_url)
       VALUES (?, ?, ?, ?, FALSE, ?)`,
      [userId, title, message, type, targetUrl]
    );
  } catch (error) {
    console.error('Error creating notification:', error.message);
  }
};

// GET /api/notifications/user/:userId or GET /api/notifications?user_id=X
exports.getUserNotifications = async (req, res) => {
  try {
    const userId = req.params.userId || req.query.user_id;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'userId is required' });
    }

    const [rows] = await pool.query(
      'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC',
      [userId]
    );

    res.json({ success: true, count: rows.length, notifications: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/notifications/:id/read
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    await pool.query('UPDATE notifications SET is_read = TRUE WHERE notification_id = ?', [id]);
    res.json({ success: true, message: 'Notification marked as read' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/notifications/user/:userId/read-all
exports.markAllAsRead = async (req, res) => {
  try {
    const { userId } = req.params;
    await pool.query('UPDATE notifications SET is_read = TRUE WHERE user_id = ?', [userId]);
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/notifications/:id
exports.deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM notifications WHERE notification_id = ?', [id]);
    res.json({ success: true, message: 'Notification deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
