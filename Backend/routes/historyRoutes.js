const express = require('express');
const router = express.Router();
const historyController = require('../controllers/historyController');

router.get('/', historyController.getUserReadingHistory);
router.post('/', historyController.saveReadingProgress);

module.exports = router;
