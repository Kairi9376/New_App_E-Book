const express = require('express');
const router = express.Router();
const bookController = require('../controllers/bookController');

router.get('/', bookController.getAllBooks);

// # ເຮັດຫຍັງ: ປະກາດ GET /deleted ໄວ້ *ກ່ອນ* GET /:id
// # ຍ້ອນຫຍັງ: Express ຈັບຄູ່ route ຕາມລຳດັບທີ່ປະກາດ ຖ້າວາງໄວ້ຫຼັງ /:id
// #          ຄຳວ່າ "deleted" ຈະຖືກອ່ານເປັນ id ແລ້ວຄືນ "Book not found"
// #          ໂດຍບໍ່ມີ error ບອກວ່າ route ຜິດ - ເປັນ bug ທີ່ຫາສາເຫດຍາກຫຼາຍ
// # ແກ້ຈາກສ່ວນໃດ: ໄຟລ໌ນີ້ມີແຕ່ GET / ແລະ GET /:id ບໍ່ມີ /deleted ເລີຍ
// # ແກ້ເຮັດຫຍັງ: ລຳດັບນີ້ຫ້າມສະຫຼັບ - route ທີ່ເປັນຄຳຄົງທີ່ຕ້ອງມາກ່ອນ :id ສະເໝີ
router.get('/deleted', bookController.getDeletedBooks);

router.get('/:id', bookController.getBookById);
router.post('/', bookController.createBook);
router.put('/:id', bookController.updateBook);
router.put('/:id/status', bookController.updateBookStatus);
// # ເຮັດຫຍັງ: ເພີ່ມ route ກູ້ຄືນປຶ້ມ ຄູ່ກັບ DELETE /:id ທີ່ເປັນ soft delete
// # ຍ້ອນຫຍັງ: client ເອີ້ນ PUT /:id/restore ມາຢູ່ແລ້ວ ແຕ່ບໍ່ມີ route ຮັບ ຈຶ່ງ 404
// # ແກ້ຈາກສ່ວນໃດ: ໄຟລ໌ນີ້ມີແຕ່ delete ບໍ່ມີທາງກູ້ຄືນ
// # ແກ້ເຮັດຫຍັງ: ວາງໄວ້ຄູ່ກັບ /:id/status ເພາະເປັນຮູບແບບ path ດຽວກັນ
router.put('/:id/restore', bookController.restoreBook);
router.post('/:id/increment-readers', bookController.incrementReadersCount);
router.delete('/:id', bookController.deleteBook);

module.exports = router;
