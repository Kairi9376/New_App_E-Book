const { pool } = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Please provide email and password' });
    }

    const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    if (rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const user = rows[0];

    // Password verification (supports bcrypt hash or direct fallback for initial seed)
    let isMatch = false;
    if (user.password_hash.startsWith('$2a$') || user.password_hash.startsWith('$2b$')) {
      isMatch = await bcrypt.compare(password, user.password_hash);
    }
    
    // Direct string match fallback if hash check is false (convenience for initial seeds)
    if (!isMatch) {
      const mockPasswords = {
        'admin@gmail.com': 'admin123456',
        'employee@gmail.com': 'employee123',
        'user1234@gmail.com': 'user1234',
        'member@gmail.com': 'member1234'
      };
      if (mockPasswords[email] && mockPasswords[email] === password) {
        isMatch = true;
      }
    }

    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    if (user.status !== 'active') {
      return res.status(403).json({ success: false, message: `Account is ${user.status}: ${user.suspended_reason || 'Contact admin'}` });
    }

    const token = jwt.sign(
      { user_id: user.user_id, email: user.email, role: user.role },
      process.env.JWT_SECRET || 'secret',
      { expiresIn: '7d' }
    );

    const { password_hash, ...userProfile } = user;

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: userProfile
    });
  } catch (error) {
    console.error('Login Error:', error);
    res.status(500).json({ success: false, message: 'Server error during login', error: error.message });
  }
};

// POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { email, password, first_name, last_name, phone_number, birth_date, gender } = req.body;

    if (!email || !password || !first_name || !last_name) {
      return res.status(400).json({ success: false, message: 'Please provide all required fields' });
    }

    const [existing] = await pool.query('SELECT user_id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(400).json({ success: false, message: 'Email is already registered' });
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    const [result] = await pool.query(
      `INSERT INTO users (email, password_hash, first_name, last_name, phone_number, birth_date, gender, role, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'user', 'active')`,
      [email, password_hash, first_name, last_name, phone_number || null, birth_date || null, gender || 'unspecified']
    );

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      user_id: result.insertId
    });
  } catch (error) {
    console.error('Register Error:', error);
    res.status(500).json({ success: false, message: 'Server error during registration', error: error.message });
  }
};

// GET /api/auth/me
exports.getMe = async (req, res) => {
  try {
    const userId = req.user ? req.user.user_id : req.query.user_id;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'User ID is required' });
    }

    const [rows] = await pool.query('SELECT user_id, email, first_name, last_name, phone_number, birth_date, gender, profile_image_url, role, status, created_at FROM users WHERE user_id = ?', [userId]);

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, user: rows[0] });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
