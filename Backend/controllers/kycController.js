const { pool } = require('../config/db');
const { deleteOldFile } = require('../utils/fileUtils');
const { createNotification } = require('./notificationController');

// GET /api/kyc
exports.getAllKyc = async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT k.*, u.first_name, u.last_name, u.email,
             r.first_name AS reviewer_first_name, r.last_name AS reviewer_last_name
      FROM kyc_verifications k
      JOIN users u ON k.user_id = u.user_id
      LEFT JOIN users r ON k.reviewed_by = r.user_id
      ORDER BY k.created_at DESC
    `);
    res.json({ success: true, count: rows.length, kyc_list: rows });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/kyc
exports.submitKyc = async (req, res) => {
  try {
    const { user_id, document_type, document_number, document_image_url, selfie_image_url, is_student, school_name } = req.body;

    if (!user_id || !document_type || !document_number || !document_image_url) {
      return res.status(400).json({ success: false, message: 'Please provide required KYC document details' });
    }

    // Check if user already submitted a KYC record previously and clean up old files
    const [existingRows] = await pool.query('SELECT document_image_url, selfie_image_url FROM kyc_verifications WHERE user_id = ?', [user_id]);
    if (existingRows.length > 0) {
      for (const row of existingRows) {
        if (document_image_url && document_image_url !== row.document_image_url) {
          deleteOldFile(row.document_image_url);
        }
        if (selfie_image_url && selfie_image_url !== row.selfie_image_url) {
          deleteOldFile(row.selfie_image_url);
        }
      }
    }

    const [result] = await pool.query(
      `INSERT INTO kyc_verifications (user_id, document_type, document_number, document_image_url, selfie_image_url, is_student, school_name, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')`,
      [user_id, document_type, document_number, document_image_url, selfie_image_url || '', is_student ? 1 : 0, school_name || null]
    );

    res.status(201).json({ success: true, message: 'KYC submitted successfully', kyc_id: result.insertId });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/kyc/user/:userId
exports.getUserKyc = async (req, res) => {
  try {
    const { userId } = req.params;
    const [rows] = await pool.query(`
      SELECT k.*, u.first_name, u.last_name, u.email
      FROM kyc_verifications k
      JOIN users u ON k.user_id = u.user_id
      WHERE k.user_id = ?
      ORDER BY k.created_at DESC
      LIMIT 1
    `, [userId]);

    if (rows.length === 0) {
      return res.json({ success: true, kyc: null, message: 'No KYC submission found' });
    }

    res.json({ success: true, kyc: rows[0] });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateKycStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, reviewed_by, rejection_reason } = req.body;

    if (!['pending', 'approved', 'rejected'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status value' });
    }

    const [kycRows] = await pool.query('SELECT user_id FROM kyc_verifications WHERE kyc_id = ?', [id]);

    await pool.query(
      `UPDATE kyc_verifications 
       SET status = ?, reviewed_by = ?, rejection_reason = ?
       WHERE kyc_id = ?`,
      [status, reviewed_by || null, rejection_reason || null, id]
    );

    if (kycRows.length > 0) {
      const targetUserId = kycRows[0].user_id;
      if (status === 'approved') {
        await createNotification({
          userId: targetUserId,
          title: '🎉 ຢືນຢັນຕົວຕົນ (KYC) ສຳເລັດແລ້ວ!',
          message: 'ບັນຊີຂອງທ່ານໄດ້ຮັບການອະນຸມັດ KYC ຮຽບຮ້ອຍແລ້ວ ສາມາດສະໝັກແພັກເກັດສະມາຊິກເພື່ອເລີ່ມໃຊ້ງານໄດ້ທັນທີ',
          type: 'kyc',
        });
      } else if (status === 'rejected') {
        await createNotification({
          userId: targetUserId,
          title: '⚠️ ການຢືນຢັນຕົວຕົນ (KYC) ບໍ່ຜ່ານການອະນຸມັດ',
          message: `ເຫດຜົນ: ${rejection_reason || 'ເອກະສານບໍ່ຈະແຈ້ງ'} ກະລຸນາຍື່ນເອກະສານແກ້ໄຂใหມ່ອີກຄັ້ງ`,
          type: 'kyc',
        });
      }
    }

    res.json({ success: true, message: `KYC verification status updated to ${status}` });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
