const express = require('express');
const router = express.Router();
const memberController = require('../controllers/memberController');
const { authenticate, authorizeAdmin } = require('../middleware/auth');

router.get('/', authenticate, memberController.getAllMembers);
router.get('/expiring', authenticate, memberController.getUpcomingExpiries);
router.get('/expired', authenticate, memberController.getExpiredMembers);
router.get('/:id', authenticate, memberController.getMemberById);

router.post('/', authenticate, memberController.createMember);
router.put('/:id', authenticate, memberController.updateMember);
router.delete('/:id', authenticate, authorizeAdmin, memberController.deleteMember);

module.exports = router;
