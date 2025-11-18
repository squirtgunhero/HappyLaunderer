const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { requireDriver } = require('../middleware/auth');

// Create new order
router.post('/', orderController.createOrder);

// Get all orders for current user
router.get('/', orderController.getUserOrders);

// Get specific order details
router.get('/:id', orderController.getOrderById);

// Update order status (driver/admin only)
router.put('/:id', requireDriver, orderController.updateOrderStatus);

// Update driver location
router.put('/:id/location', requireDriver, orderController.updateDriverLocation);

// Cancel order
router.post('/:id/cancel', orderController.cancelOrder);

module.exports = router;

