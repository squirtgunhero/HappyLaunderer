const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { verifyClerkToken } = require('../middleware/auth');

// Create or update user profile
router.post('/profile', verifyClerkToken, authController.upsertProfile);

// Get user profile
router.get('/profile', verifyClerkToken, authController.getProfile);

// Update user profile
router.put('/profile', verifyClerkToken, authController.updateProfile);

// Add saved address
router.post('/profile/addresses', verifyClerkToken, authController.addAddress);

// Remove saved address
router.delete('/profile/addresses/:index', verifyClerkToken, authController.removeAddress);

module.exports = router;

