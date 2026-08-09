const express = require('express');
const router = express.Router();
const bookmarkController = require('../controllers/bookmarkController');

// # ເຮັດຫຍັງ: ຕິດ auth middleware ໃສ່ທຸກ route ໃນໄຟລ໌ນີ້
// # ຍ້ອນຫຍັງ: ແຕ່ກ່ອນທຸກ endpoint ເປີດໃຫ້ໃຜກໍ່ໄດ້ເອີ້ນ ໂດຍບໍ່ຕ້ອງມີ token
// # ແກ້ຈາກສ່ວນໃດ: ໄຟລ໌ນີ້ປະກາດ router.<method> ໂດຍບໍ່ມີ middleware ຄັ່ນເລີຍ
// # ແກ້ເຮັດຫຍັງ: ແຕ່ລະ route ບອກສິດຂອງຕົນຊັດເຈນ - ອ່ານແລ້ວຮູ້ທັນທີວ່າໃຜເອີ້ນໄດ້
const { requireAuth, requireAdmin, requireStaff, requireSelfOrAdmin } = require('../middleware/auth');

router.get('/', requireAuth, bookmarkController.getUserBookmarks);
router.post('/', requireAuth, bookmarkController.addBookmark);
router.delete('/', requireAuth, bookmarkController.removeBookmark);

module.exports = router;
