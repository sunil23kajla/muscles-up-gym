const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate, authorizeAdmin } = require('../middleware/auth');

router.post('/register', authController.register);
router.post('/login', authController.login);

// Admin-protected requests approval endpoints
router.get('/pending-requests', authenticate, authorizeAdmin, authController.getPendingRequests);
router.post('/update-status', authenticate, authorizeAdmin, authController.updateRequestStatus);

// Password Change & Account Detail Transfers (Self Profile Update)
router.post('/change-password', authenticate, authController.changePassword);
router.put('/update-profile', authenticate, authController.updateProfile);

// Staff Directory and Administrative override tools
router.get('/staff', authenticate, authorizeAdmin, authController.getStaffList);
router.delete('/staff/:id', authenticate, authorizeAdmin, authController.deleteStaff);
router.post('/admin-reset-password', authenticate, authorizeAdmin, authController.adminResetPassword);

module.exports = router;
