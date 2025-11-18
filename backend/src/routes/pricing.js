const express = require('express');
const router = express.Router();
const pricingController = require('../controllers/pricingController');

// Calculate price for service
router.post('/calculate', pricingController.calculatePrice);

// Get pricing tiers
router.get('/tiers', pricingController.getPricingTiers);

module.exports = router;

