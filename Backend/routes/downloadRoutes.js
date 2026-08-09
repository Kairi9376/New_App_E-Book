const express = require('express');
const router = express.Router();
const downloadController = require('../controllers/downloadController');

// # ເຮັດຫຍັງ: ຕິດ auth middleware ໃສ່ທຸກ route ໃນໄຟລ໌ນີ້
// # ຍ້ອນຫຍັງ: ແຕ່ກ່ອນທຸກ endpoint ເປີດໃຫ້ໃຜກໍ່ໄດ້ເອີ້ນ ໂດຍບໍ່ຕ້ອງມີ token
// # ແກ້ຈາກສ່ວນໃດ: ໄຟລ໌ນີ້ປະກາດ router.<method> ໂດຍບໍ່ມີ middleware ຄັ່ນເລີຍ
// # ແກ້ເຮັດຫຍັງ: ແຕ່ລະ route ບອກສິດຂອງຕົນຊັດເຈນ - ອ່ານແລ້ວຮູ້ທັນທີວ່າໃຜເອີ້ນໄດ້
const { requireAuth, requireAdmin, requireStaff, requireSelfOrAdmin } = require('../middleware/auth');

router.get('/', requireAuth, downloadController.getUserDownloads);
router.get('/check', requireAuth, downloadController.checkDownloadPermission);
router.post('/', requireAuth, downloadController.recordDownload);
router.delete('/:download_id', requireAuth, downloadController.deleteDownload);

module.exports = router;
