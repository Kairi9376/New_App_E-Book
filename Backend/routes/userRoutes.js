const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

router.get('/', userController.getAllUsers);
// # ເຮັດຫຍັງ: ເພີ່ມ route POST / ໃຫ້ຄູ່ກັບ userController.createUser
// # ຍ້ອນຫຍັງ: client ຍິງ POST /api/users ມາຢູ່ແລ້ວ ແຕ່ບໍ່ມີ route ຮັບ
// #          Express ຈຶ່ງຄືນ 404 HTML ເຮັດໃຫ້ເພີ່ມພະນັກງານໃນໜ້າ Admin ບໍ່ໄດ້
// # ແກ້ຈາກສ່ວນໃດ: ໄຟລ໌ນີ້ມີແຕ່ GET / , GET /:id , PUT /:id ແລະ PUT /:id/status
// # ແກ້ເຮັດຫຍັງ: ວາງໄວ້ກ່ອນ /:id ບໍ່ຈຳເປັນ ເພາະ method ຕ່າງກັນ ແຕ່ຈັດເປັນຄູ່ກັບ GET /
router.post('/', userController.createUser);
router.get('/:id', userController.getUserById);
router.put('/:id', userController.updateUserProfile);
router.put('/:id/status', userController.updateUserStatus);

module.exports = router;
