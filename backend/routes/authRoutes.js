const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate, authorizeAdmin } = require('../middleware/auth');

router.post('/register', authController.register);
router.post('/login', authController.login);

// Admin-protected requests approval endpoints
router.get('/pending-requests', authenticate, authorizeAdmin, authController.getPendingRequests);
router.post('/update-status', authenticate, authorizeAdmin, authController.updateRequestStatus);

module.exports = router;
