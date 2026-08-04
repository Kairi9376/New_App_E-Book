const express = require('express');
const router = express.Router();
const packageController = require('../controllers/packageController');

router.get('/', packageController.getAllPackages);
router.post('/', packageController.createPackage);
router.put('/:id/status', packageController.updatePackageStatus);
router.put('/:id', packageController.updatePackage);

module.exports = router;
