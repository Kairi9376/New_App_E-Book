const jwt = require('jsonwebtoken');

// # ເຮັດຫຍັງ: ເພີ່ມ auth middleware ໃໝ່ທັງໝົດ
// # ຍ້ອນຫຍັງ: ແຕ່ກ່ອນໂປຣເຈັກນີ້ບໍ່ມີການກວດສິດໃນ endpoint ໃດເລີຍ ພິສູດໄດ້ດ້ວຍ curl
// #          ໂດຍບໍ່ມີ token: POST /api/users ສ້າງບັນຊີ admin ໄດ້ ແລະ
// #          PUT /api/users/:id/status ລະງັບບັນຊີຄົນອື່ນໄດ້ ໃຜຮູ້ URL ກໍ່ຍຶດລະບົບໄດ້
// # ແກ້ຈາກສ່ວນໃດ: Backend/middleware/ ມີແຕ່ upload.js ແລະ req.user ບໍ່ເຄີຍຖືກ set
// #              ຈຶ່ງເຮັດໃຫ້ authController.getMe ຕ້ອງອາໄສ ?user_id= ຈາກ query ທີ່ປອມໄດ້
// # ແກ້ເຮັດຫຍັງ: ລວມການກວດ token ແລະ role ໄວ້ບ່ອນດຽວ ໃຫ້ route ປະກາດສິດຂອງຕົນຊັດເຈນ

// ບົດບາດຕາມ ENUM ຂອງຕາຕະລາງ users
const ROLE_ADMIN = 'admin';
const ROLE_EMPLOYEE = 'employee';

function readToken(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return null;

  try {
    return jwt.verify(header.slice(7), process.env.JWT_SECRET);
  } catch (_) {
    // token ໝົດອາຍຸ / ຖືກແກ້ / ເຊັນດ້ວຍ secret ອື່ນ
    return null;
  }
}

/// ຕ້ອງ login ກ່ອນ - ວາງ payload ຂອງ token ໄວ້ທີ່ req.user ໃຫ້ຊັ້ນຕໍ່ໄປໃຊ້
function requireAuth(req, res, next) {
  const payload = readToken(req);
  if (!payload) {
    return res.status(401).json({
      success: false,
      message: 'ຕ້ອງເຂົ້າສູ່ລະບົບກ່ອນ (token ບໍ່ຖືກຕ້ອງ ຫຼື ໝົດອາຍຸ)',
    });
  }
  req.user = payload;
  next();
}

/// ຈຳກັດສະເພາະ role ທີ່ລະບຸ - ໃຊ້ຕໍ່ຈາກ requireAuth ສະເໝີ
function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res
        .status(401)
        .json({ success: false, message: 'ຕ້ອງເຂົ້າສູ່ລະບົບກ່ອນ' });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'ບໍ່ມີສິດເຂົ້າເຖິງສ່ວນນີ້',
      });
    }
    next();
  };
}

// # ເຮັດຫຍັງ: ອະນຸຍາດເມື່ອເປັນເຈົ້າຂອງຂໍ້ມູນເອງ ຫຼື ເປັນ admin
// # ຍ້ອນຫຍັງ: PUT /api/users/:id ຖືກເອີ້ນຈາກ 2 ບ່ອນ - admin_user_dialog (admin ແກ້ຜູ້ອື່ນ)
// #          ແລະ profile_screen (ຜູ້ໃຊ້ປ່ຽນຮູບໂປຣໄຟລ໌ຕົນເອງ) ຈຶ່ງຈຳກັດເປັນ admin
// #          ຢ່າງດຽວບໍ່ໄດ້ ຈະເຮັດໃຫ້ຜູ້ໃຊ້ທົ່ວໄປແກ້ໂປຣໄຟລ໌ຕົນເອງບໍ່ໄດ້
// # ແກ້ຈາກສ່ວນໃດ: ເປັນກົດໃໝ່ ແຕ່ກ່ອນບໍ່ມີການກວດຫຍັງເລີຍ
// # ແກ້ເຮັດຫຍັງ: ຜູ້ໃຊ້ແກ້ໄດ້ແຕ່ຂອງຕົນເອງ ສ່ວນ admin ແກ້ໄດ້ທຸກຄົນ
function requireSelfOrAdmin(paramName = 'id') {
  return (req, res, next) => {
    if (!req.user) {
      return res
        .status(401)
        .json({ success: false, message: 'ຕ້ອງເຂົ້າສູ່ລະບົບກ່ອນ' });
    }

    const target = String(req.params[paramName]);
    const self = String(req.user.user_id);

    if (req.user.role === ROLE_ADMIN || target === self) return next();

    return res.status(403).json({
      success: false,
      message: 'ແກ້ໄຂໄດ້ສະເພາະຂໍ້ມູນຂອງຕົນເອງເທົ່ານັ້ນ',
    });
  };
}

module.exports = {
  ROLE_ADMIN,
  ROLE_EMPLOYEE,
  requireAuth,
  requireRole,
  requireSelfOrAdmin,
  requireAdmin: requireRole(ROLE_ADMIN),
  requireStaff: requireRole(ROLE_ADMIN, ROLE_EMPLOYEE),
};
