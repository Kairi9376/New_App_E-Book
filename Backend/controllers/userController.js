const { pool } = require('../config/db');
const { deleteOldFile, isSameFilePath } = require('../utils/fileUtils');
const bcrypt = require('bcryptjs');

// # ເຮັດຫຍັງ: ເພີ່ມ createUser ໃໝ່ທັງໝົດ
// # ຍ້ອນຫຍັງ: ໜ້າ Admin ມີ dialog ເພີ່ມຜູ້ໃຊ້/ພະນັກງານ ແລະ ຝັ່ງ client ເອີ້ນ
// #          POST /api/users ຢູ່ແລ້ວ ແຕ່ backend ບໍ່ເຄີຍມີ route ນີ້ເລີຍ
// #          ຄຳຮ້ອງຈຶ່ງຕົກໄປທີ່ 404 ຂອງ Express ເຮັດໃຫ້ "ເພີ່ມພະນັກງານບໍ່ໄດ້"
// # ແກ້ຈາກສ່ວນໃດ: userController.js ມີແຕ່ getAllUsers, getUserById,
// #              updateUserProfile ແລະ updateUserStatus (ບໍ່ມີການສ້າງ)
// # ແກ້ເຮັດຫຍັງ: ສ້າງບັນຊີໄດ້ຄົບທຸກ role ໂດຍ hash ລະຫັດຜ່ານດ້ວຍ bcrypt
// #             ແບບດຽວກັນກັບ authController.register ເພື່ອໃຫ້ login ໄດ້ຄືກັນ
// POST /api/users
exports.createUser = async (req, res) => {
  try {
    const {
      email,
      password,
      first_name,
      last_name,
      phone_number,
      birth_date,
      gender,
      profile_image_url,
      role,
      status,
    } = req.body;

    if (!email || !password || !first_name || !last_name) {
      return res.status(400).json({
        success: false,
        message: 'ຕ້ອງປ້ອນ email, password, first_name ແລະ last_name',
      });
    }

    // ENUM ໃນ schema ຮັບພຽງ 3 role - ຄ່ານອກນີ້ຈະຖືກ MySQL ປະຕິເສດ
    // ຈຶ່ງກວດຢູ່ນີ້ກ່ອນເພື່ອຄືນ error ທີ່ອ່ານເຂົ້າໃຈ ແທນ SQL error ດິບ
    const allowedRoles = ['admin', 'employee', 'user'];
    const allowedStatus = ['active', 'suspended', 'banned', 'pending'];
    const safeRole = allowedRoles.includes(role) ? role : 'user';
    const safeStatus = allowedStatus.includes(status) ? status : 'active';

    const [existing] = await pool.query(
      'SELECT user_id FROM users WHERE email = ?',
      [email]
    );
    if (existing.length > 0) {
      return res
        .status(400)
        .json({ success: false, message: 'ອີເມວນີ້ຖືກໃຊ້ແລ້ວ' });
    }

    // phone_number ເປັນ UNIQUE ໃນ schema - ສົ່ງສະຕຣິງຫວ່າງມາຫຼາຍລາຍຈະຊົນກັນ
    // ຈຶ່ງແປງເປັນ NULL ເພາະ MySQL ຍອມໃຫ້ NULL ຊ້ຳກັນໄດ້ໃນ UNIQUE index
    const phone = phone_number && phone_number.trim() !== '' ? phone_number.trim() : null;
    if (phone) {
      const [dupPhone] = await pool.query(
        'SELECT user_id FROM users WHERE phone_number = ?',
        [phone]
      );
      if (dupPhone.length > 0) {
        return res
          .status(400)
          .json({ success: false, message: 'ເບີໂທລະສັບນີ້ຖືກໃຊ້ແລ້ວ' });
      }
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    const [result] = await pool.query(
      `INSERT INTO users
         (email, password_hash, first_name, last_name, phone_number,
          birth_date, gender, profile_image_url, role, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        email,
        password_hash,
        first_name,
        last_name,
        phone,
        birth_date || null,
        gender || 'unspecified',
        profile_image_url && profile_image_url.trim() !== ''
          ? profile_image_url.trim()
          : null,
        safeRole,
        safeStatus,
      ]
    );

    res.status(201).json({
      success: true,
      message: 'ສ້າງບັນຊີຜູ້ໃຊ້ສຳເລັດ',
      user_id: result.insertId,
    });
  } catch (error) {
    console.error('Create User Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

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

// PUT /api/users/:id (Update User Profile & Avatar & Password)
exports.updateUserProfile = async (req, res) => {
  try {
    const { id } = req.params;
    const { first_name, last_name, phone_number, birth_date, gender, profile_image_url, password } = req.body;

    const [existingRows] = await pool.query('SELECT profile_image_url FROM users WHERE user_id = ?', [id]);
    if (existingRows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const currentProfileImage = existingRows[0].profile_image_url;

    // Delete old profile picture if new profile_image_url is provided and different
    if (profile_image_url && !isSameFilePath(profile_image_url, currentProfileImage)) {
      deleteOldFile(currentProfileImage);
    }

    let password_hash = null;
    if (password && password.trim().length > 0) {
      const salt = await bcrypt.genSalt(10);
      password_hash = await bcrypt.hash(password.trim(), salt);
    }

    await pool.query(
      `UPDATE users 
       SET first_name = COALESCE(?, first_name),
           last_name = COALESCE(?, last_name),
           phone_number = COALESCE(?, phone_number),
           birth_date = COALESCE(?, birth_date),
           gender = COALESCE(?, gender),
           profile_image_url = COALESCE(?, profile_image_url),
           password_hash = COALESCE(?, password_hash)
       WHERE user_id = ?`,
      [first_name || null, last_name || null, phone_number || null, birth_date || null, gender || null, profile_image_url || null, password_hash || null, id]
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
