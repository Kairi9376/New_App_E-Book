const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// # ເຮັດຫຍັງ: ຕິດ auth middleware ໃສ່ທຸກ route ຂອງຜູ້ໃຊ້
// # ຍ້ອນຫຍັງ: ພິສູດແລ້ວວ່າແຕ່ກ່ອນ POST /api/users ສ້າງບັນຊີ admin ໄດ້ ແລະ
// #          PUT /api/users/:id/status ລະງັບບັນຊີຄົນອື່ນໄດ້ ໂດຍບໍ່ຕ້ອງມີ token ເລີຍ
// # ແກ້ຈາກສ່ວນໃດ: ໄຟລ໌ນີ້ປະກາດ router.<method> ໂດຍບໍ່ມີການກວດສິດ
// # ແກ້ເຮັດຫຍັງ: ຈຳກັດການຈັດການຜູ້ໃຊ້ໃຫ້ admin ເທົ່ານັ້ນ
const {
  requireAuth,
  requireAdmin,
  requireSelfOrAdmin,
} = require('../middleware/auth');

router.get('/', requireAuth, requireAdmin, userController.getAllUsers);
router.post('/', requireAuth, requireAdmin, userController.createUser);

// # ເຮັດຫຍັງ: ປະກາດ GET /profile ໄວ້ *ກ່ອນ* GET /:id
// # ຍ້ອນຫຍັງ: ເຫດຜົນດຽວກັນກັບ /books/deleted - ຖ້າວາງໄວ້ຫຼັງ /:id ຄຳວ່າ "profile"
// #          ຈະຖືກອ່ານເປັນ user id ແລ້ວຄືນ "ບໍ່ພົບຜູ້ໃຊ້" ແທນທີ່ຈະຄືນໂປຣໄຟລ໌
// # ແກ້ຈາກສ່ວນໃດ: ໄຟລ໌ນີ້ບໍ່ມີ route ສຳລັບຜູ້ໃຊ້ທີ່ login ຢູ່ເລີຍ
// # ແກ້ເຮັດຫຍັງ: ຄູ່ກັບການແກ້ຝັ່ງ client ທີ່ປ່ຽນຈາກ /user/profile ເປັນ /users/profile
router.get('/profile', requireAuth, userController.getMyProfile);

router.get('/:id', requireAuth, requireAdmin, userController.getUserById);

// # ເຮັດຫຍັງ: ໃຊ້ requireSelfOrAdmin ແທນ requireAdmin ສະເພາະ route ນີ້
// # ຍ້ອນຫຍັງ: PUT /:id ຖືກເອີ້ນຈາກ admin_user_dialog (admin ແກ້ຜູ້ອື່ນ) ແລະ
// #          profile_screen (ຜູ້ໃຊ້ປ່ຽນຮູບໂປຣໄຟລ໌ຕົນເອງ) ຖ້າຈຳກັດເປັນ admin
// #          ຢ່າງດຽວ ຜູ້ໃຊ້ທົ່ວໄປຈະອັບເດດໂປຣໄຟລ໌ຕົນເອງບໍ່ໄດ້
// # ແກ້ຈາກສ່ວນໃດ: route ນີ້ບໍ່ເຄີຍກວດຫຍັງມາກ່ອນ
// # ແກ້ເຮັດຫຍັງ: ຜູ້ໃຊ້ແກ້ໄດ້ແຕ່ຂອງຕົນເອງ ສ່ວນ admin ແກ້ໄດ້ທຸກຄົນ
router.put('/:id', requireAuth, requireSelfOrAdmin('id'), userController.updateUserProfile);

router.put('/:id/status', requireAuth, requireAdmin, userController.updateUserStatus);

module.exports = router;
