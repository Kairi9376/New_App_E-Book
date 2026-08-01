const express = require('express');
const router = express.Router();
const bookmarkController = require('../controllers/bookmarkController');

router.get('/', bookmarkController.getUserBookmarks);
router.post('/', bookmarkController.addBookmark);
router.delete('/', bookmarkController.removeBookmark);

module.exports = router;
