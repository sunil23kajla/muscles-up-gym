const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');
const { authenticate } = require('../middleware/auth');

router.post('/mark', authenticate, attendanceController.markAttendance);
router.get('/daily', authenticate, attendanceController.getDailyAttendance);

router.post('/workout', authenticate, attendanceController.assignWorkoutPlan);
router.get('/workout/:memberId', authenticate, attendanceController.getWorkoutPlan);

module.exports = router;
