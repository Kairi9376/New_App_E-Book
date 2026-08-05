const express = require('express');
const router = express.Router();
const downloadController = require('../controllers/downloadController');

router.get('/', downloadController.getUserDownloads);
router.post('/', downloadController.recordDownload);
router.delete('/:download_id', downloadController.deleteDownload);

module.exports = router;

