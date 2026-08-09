const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');

// # ເຮັດຫຍັງ: ຕິດ auth middleware ໃສ່ທຸກ route ໃນໄຟລ໌ນີ້
// # ຍ້ອນຫຍັງ: ແຕ່ກ່ອນທຸກ endpoint ເປີດໃຫ້ໃຜກໍ່ໄດ້ເອີ້ນ ໂດຍບໍ່ຕ້ອງມີ token
// # ແກ້ຈາກສ່ວນໃດ: ໄຟລ໌ນີ້ປະກາດ router.<method> ໂດຍບໍ່ມີ middleware ຄັ່ນເລີຍ
// # ແກ້ເຮັດຫຍັງ: ແຕ່ລະ route ບອກສິດຂອງຕົນຊັດເຈນ - ອ່ານແລ້ວຮູ້ທັນທີວ່າໃຜເອີ້ນໄດ້
const { requireAuth, requireAdmin, requireStaff, requireSelfOrAdmin } = require('../middleware/auth');

router.get('/', requireAuth, categoryController.getAllCategories);
router.post('/', requireAuth, requireStaff, categoryController.createCategory);
router.put('/:id', requireAuth, requireStaff, categoryController.updateCategory);
router.delete('/:id', requireAuth, requireStaff, categoryController.deleteCategory);

module.exports = router;
