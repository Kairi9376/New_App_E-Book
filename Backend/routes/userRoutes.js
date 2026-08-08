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

// # ເຮັດຫຍັງ: ປະກາດ GET /profile ໄວ້ *ກ່ອນ* GET /:id
// # ຍ້ອນຫຍັງ: ເຫດຜົນດຽວກັນກັບ /books/deleted - ຖ້າວາງໄວ້ຫຼັງ /:id ຄຳວ່າ "profile"
// #          ຈະຖືກອ່ານເປັນ user id ແລ້ວຄືນ "ບໍ່ພົບຜູ້ໃຊ້" ແທນທີ່ຈະຄືນໂປຣໄຟລ໌
// # ແກ້ຈາກສ່ວນໃດ: ໄຟລ໌ນີ້ບໍ່ມີ route ສຳລັບຜູ້ໃຊ້ທີ່ login ຢູ່ເລີຍ
// # ແກ້ເຮັດຫຍັງ: ຄູ່ກັບການແກ້ຝັ່ງ client ທີ່ປ່ຽນຈາກ /user/profile ເປັນ /users/profile
router.get('/profile', userController.getMyProfile);

router.get('/:id', userController.getUserById);
router.put('/:id', userController.updateUserProfile);
router.put('/:id/status', userController.updateUserStatus);

module.exports = router;
