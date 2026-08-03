const express = require('express');
const router = express.Router();
const kycController = require('../controllers/kycController');

router.get('/', kycController.getAllKyc);
router.get('/user/:userId', kycController.getUserKyc);
router.post('/', kycController.submitKyc);
router.put('/:id/status', kycController.updateKycStatus);

module.exports = router;
