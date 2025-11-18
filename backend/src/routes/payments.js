const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');

// Process payment for an order
router.post('/charge', paymentController.processPayment);

// Get payment details
router.get('/:orderId', paymentController.getPaymentByOrderId);

// Get all payments for user
router.get('/', paymentController.getUserPayments);

// Note: Webhook endpoint is registered directly in index.js
// to bypass authentication and receive raw body for signature verification

module.exports = router;

