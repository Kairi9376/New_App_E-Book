const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// # ເຮັດຫຍັງ: ຕິດ requireAuth ໃສ່ /me ສ່ວນ /login ກັບ /register ປະໄວ້ເປີດ
// # ຍ້ອນຫຍັງ: ສອງ route ນັ້ນຕ້ອງເປີດ ເພາະເປັນທາງດຽວທີ່ຈະໄດ້ token ມາຕັ້ງແຕ່ຕົ້ນ
// #          ສ່ວນ /me ແຕ່ກ່ອນອາໄສ ?user_id= ຈາກ query ເຊິ່ງໃຜກໍ່ໃສ່ເລກຄົນອື່ນໄດ້
// # ແກ້ຈາກສ່ວນໃດ: ໄຟລ໌ນີ້ບໍ່ມີການກວດສິດເລີຍທັງ 3 route
// # ແກ້ເຮັດຫຍັງ: /me ຄືນຂໍ້ມູນຈາກ token ຂອງຜູ້ເອີ້ນເອງເທົ່ານັ້ນ
const { requireAuth } = require('../middleware/auth');

router.post('/login', authController.login);
router.post('/register', authController.register);
router.get('/me', requireAuth, authController.getMe);

module.exports = router;
