const { pool } = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, phone, phone_number, login_input, password } = req.body;
    const inputVal = (email || phone || phone_number || login_input || '').trim();

    if (!inputVal || !password) {
      return res.status(400).json({ success: false, message: 'ກະລຸນາກອກອີເມວ/ເບີໂທລະສັບ ແລະ ລະຫັດຜ່ານ' });
    }

    const cleanInput = inputVal.toLowerCase();
    const cleanEmail = cleanInput;
    const rawInput = inputVal;
    const cleanPassword = password.trim();

    // # ເຮັດຫຍັງ: ຕັດ 3 ທາງລັດຂອງການ login ອອກ ເຫຼືອແຕ່ການກວດດ້ວຍ bcrypt
    // # ຍ້ອນຫຍັງ: ຂອງເກົ່າມີຊ່ອງໂຫວ່ຮ້າຍແຮງ 3 ຢ່າງທີ່ພິສູດແລ້ວດ້ວຍ curl:
    // #   1) allowedPasswords ຝັງລະຫັດ '123456' ໄວ້ໃຫ້ທຸກບັນຊີ seed ເຮັດໃຫ້
    // #      admin@gmail.com / 123456 ເຂົ້າໄດ້ ເຖິງແມ່ນ DB ຈະເກັບ bcrypt hash ຈິງ
    // #      ແລະ ປ່ຽນລະຫັດຜ່ານກໍ່ບໍ່ຊ່ວຍ ເພາະການກວດນີ້ຢູ່ນອກ bcrypt
    // #   2) user.password_hash === cleanPassword ຍອມຮັບລະຫັດ plaintext ໃນ DB
    // #   3) mockAccounts ສ້າງ session admin (user_id 1) ຕອນ DB ຫາບໍ່ພົບ ຫຼື ລົ້ມ
    // #      ແປວ່າ DB ລົ້ມ = ໃຜກໍ່ເປັນ admin ໄດ້
    // # ແກ້ຈາກສ່ວນໃດ: ບລັອກ mockAccounts, ຂັ້ນຕອນ 2 ແລະ 3 ຂອງການທຽບລະຫັດຜ່ານ
    // # ແກ້ເຮັດຫຍັງ: ເຫຼືອທາງດຽວຄື bcrypt.compare ກັບ hash ໃນ DB
    // #             ບັນຊີທີ່ເກັບລະຫັດ plaintext ໄວ້ຈະ login ບໍ່ໄດ້ອີກ ຕ້ອງ reset ໃໝ່
    let user = null;

    const [rows] = await pool.query(
      `SELECT * FROM users
       WHERE LOWER(email) = ?
          OR phone_number = ?
          OR REPLACE(phone_number, ' ', '') = ?`,
      [cleanInput, rawInput, rawInput.replace(/\s+/g, '')]
    );
    if (rows.length > 0) {
      user = rows[0];
    }

    let isMatch = false;

    if (user && user.password_hash) {
      try {
        isMatch = await bcrypt.compare(cleanPassword, user.password_hash);
      } catch (_) {
        // hash ຮູບແບບບໍ່ຖືກຕ້ອງ (ເຊັ່ນ plaintext ເກົ່າ) - ຖືວ່າບໍ່ຜ່ານ
        isMatch = false;
      }
    }

    if (!isMatch || !user) {
      return res.status(401).json({ success: false, message: 'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ (Invalid email or password)' });
    }

    if (user.status && user.status !== 'active') {
      return res.status(403).json({ success: false, message: `ບັນຊີຖືກ ${user.status}: ${user.suspended_reason || 'ກະລຸນາຕິດຕໍ່ຜູ້ດູແລລະບົບ'}` });
    }

    const token = jwt.sign(
      { user_id: user.user_id, email: user.email, role: user.role },
      // # ເຮັດຫຍັງ: ຕັດ fallback || 'secret' ອອກ
      // # ຍ້ອນຫຍັງ: ຖ້າ env ຫາຍ token ຈະຖືກເຊັນດ້ວຍຄຳວ່າ 'secret' ທີ່ໃຜກໍ່ເດົາໄດ້
      // #          ແລ້ວປອມ token ເປັນ admin ໄດ້ທັນທີ
      // # ແກ້ຈາກສ່ວນໃດ: jwt.sign(..., process.env.JWT_SECRET || 'secret', ...)
      // # ແກ້ເຮັດຫຍັງ: server.js ກວດ JWT_SECRET ຕອນ start ຢູ່ແລ້ວ ຈຶ່ງບໍ່ຕ້ອງມີ fallback
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    const { password_hash, ...userProfile } = user;

    return res.json({
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
