const express = require('express');
const router = express.Router();
const inquiryController = require('../controllers/inquiryController');
const { authenticate, authorizeAdmin } = require('../middleware/auth');

// Public route to submit an inquiry from the landing website
router.post('/', inquiryController.createInquiry);

// Secured administrative routes
router.get('/', authenticate, inquiryController.getAllInquiries);
router.put('/:id', authenticate, inquiryController.updateInquiryStatus);
router.delete('/:id', authenticate, authorizeAdmin, inquiryController.deleteInquiry);

module.exports = router;
