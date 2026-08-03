const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscriptionController');

router.get('/', subscriptionController.getAllSubscriptions);
router.get('/user/:userId', subscriptionController.getUserSubscription);
router.post('/', subscriptionController.createSubscription);
router.put('/:id/status', subscriptionController.updateSubscriptionStatus);

module.exports = router;
