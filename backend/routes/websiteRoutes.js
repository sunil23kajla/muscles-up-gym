const express = require('express');
const router = express.Router();
const websiteController = require('../controllers/websiteController');
const { authenticate, authorizeAdmin } = require('../middleware/auth');

// Public route to fetch configurations for the website rendering
router.get('/', websiteController.getWebsiteConfig);

// Secured administrative route to update layout settings (Admin only)
router.put('/', authenticate, authorizeAdmin, websiteController.updateWebsiteSetting);

module.exports = router;
