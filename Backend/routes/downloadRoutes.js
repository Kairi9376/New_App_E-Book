const express = require('express');
const router = express.Router();
const downloadController = require('../controllers/downloadController');

router.get('/', downloadController.getUserDownloads);
router.post('/', downloadController.recordDownload);

module.exports = router;
