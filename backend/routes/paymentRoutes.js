const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authenticate } = require('../middleware/auth');

router.get('/', authenticate, paymentController.getAllPayments);
router.get('/reports', authenticate, paymentController.getFinancialReports);
router.post('/', authenticate, paymentController.createPayment);

module.exports = router;
