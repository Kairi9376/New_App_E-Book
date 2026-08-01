const express = require('express');
const router = express.Router();
const auditLogController = require('../controllers/auditLogController');

router.get('/', auditLogController.getAuditLogs);
router.post('/', auditLogController.createAuditLog);

module.exports = router;
