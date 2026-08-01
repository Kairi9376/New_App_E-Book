const express = require('express');
const router = express.Router();
const packageController = require('../controllers/packageController');

router.get('/', packageController.getAllPackages);
router.post('/', packageController.createPackage);

module.exports = router;
