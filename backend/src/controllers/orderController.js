const db = require('../config/database');
const Joi = require('joi');

// Validation schemas
const createOrderSchema = Joi.object({
  pickupAddress: Joi.object({
    street: Joi.string().required(),
    city: Joi.string().required(),
    state: Joi.string().required(),
    zipCode: Joi.string().required(),
    latitude: Joi.number(),
    longitude: Joi.number()
  }).required(),
  deliveryAddress: Joi.object({
    street: Joi.string().required(),
    city: Joi.string().required(),
    state: Joi.string().required(),
    zipCode: Joi.string().required(),
    latitude: Joi.number(),
    longitude: Joi.number()
  }).required(),
  scheduledTime: Joi.date().iso().required(),
  serviceType: Joi.string().valid('standard', 'express', 'premium').required(),
  itemCount: Joi.number().integer().min(0).default(0),
  notes: Joi.string().allow('').max(500)
});

const updateStatusSchema = Joi.object({
  status: Joi.string().valid(
    'pending',
    'picked_up',
    'in_laundry',
    'ready',
    'out_for_delivery',
    'completed',
    'cancelled'
  ).required(),
  notes: Joi.string().allow('').max(500)
});

/**
 * Create new order
 */
async function createOrder(req, res, next) {
  try {
    const { error, value } = createOrderSchema.validate(req.body);
    if (error) throw error;

    const {
      pickupAddress,
      deliveryAddress,
      scheduledTime,
      serviceType,
      itemCount,
      notes
    } = value;

    const clerkId = req.user.clerkId;

    // Get user ID from clerk_id
    const userResult = await db.query(
      'SELECT id FROM users WHERE clerk_id = $1',
      [clerkId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User profile not found. Please complete your profile first.' });
    }

    const userId = userResult.rows[0].id;

    // Calculate price based on service type
    const pricingMap = {
      standard: 25.00,
      express: 40.00,
      premium: 60.00
    };
    const price = pricingMap[serviceType];

    // Create order
    const result = await db.query(
      `INSERT INTO orders (
        user_id,
        pickup_address,
        delivery_address,
        scheduled_time,
        service_type,
        item_count,
        price,
        notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *`,
      [
        userId,
        JSON.stringify(pickupAddress),
        JSON.stringify(deliveryAddress),
        scheduledTime,
        serviceType,
        itemCount,
        price,
        notes
      ]
    );

    // Log status history
    await db.query(
      `INSERT INTO order_status_history (order_id, new_status, changed_by)
       VALUES ($1, $2, $3)`,
      [result.rows[0].id, 'pending', userId]
    );

    res.status(201).json({
      success: true,
      order: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Get all orders for current user
 */
async function getUserOrders(req, res, next) {
  try {
    const clerkId = req.user.clerkId;
    const { status, limit = 50, offset = 0 } = req.query;

    // Get user ID
    const userResult = await db.query(
      'SELECT id FROM users WHERE clerk_id = $1',
      [clerkId]
    );

    if (userResult.rows.length === 0) {
      return res.json({ success: true, orders: [] });
    }

    const userId = userResult.rows[0].id;

    // Build query
    let query = 'SELECT * FROM orders WHERE user_id = $1';
    const params = [userId];

    if (status) {
      query += ' AND status = $2';
      params.push(status);
    }

    query += ' ORDER BY created_at DESC LIMIT $' + (params.length + 1) + ' OFFSET $' + (params.length + 2);
    params.push(parseInt(limit), parseInt(offset));

    const result = await db.query(query, params);

    res.json({
      success: true,
      orders: result.rows,
      count: result.rows.length
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Get specific order by ID
 */
async function getOrderById(req, res, next) {
  try {
    const { id } = req.params;
    const clerkId = req.user.clerkId;

    // Get user ID
    const userResult = await db.query(
      'SELECT id FROM users WHERE clerk_id = $1',
      [clerkId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userId = userResult.rows[0].id;

    // Get order (ensure it belongs to the user)
    const result = await db.query(
      'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // Get status history
    const historyResult = await db.query(
      'SELECT * FROM order_status_history WHERE order_id = $1 ORDER BY created_at DESC',
      [id]
    );

    res.json({
      success: true,
      order: result.rows[0],
      statusHistory: historyResult.rows
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Update order status (driver/admin only)
 */
async function updateOrderStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { error, value } = updateStatusSchema.validate(req.body);
    if (error) throw error;

    const { status, notes } = value;

    // Get current order
    const currentOrder = await db.query(
      'SELECT * FROM orders WHERE id = $1',
      [id]
    );

    if (currentOrder.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const oldStatus = currentOrder.rows[0].status;

    // Update order status
    const result = await db.query(
      'UPDATE orders SET status = $1 WHERE id = $2 RETURNING *',
      [status, id]
    );

    // Log status change
    await db.query(
      `INSERT INTO order_status_history (order_id, old_status, new_status, notes)
       VALUES ($1, $2, $3, $4)`,
      [id, oldStatus, status, notes]
    );

    res.json({
      success: true,
      order: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Update driver location
 */
async function updateDriverLocation(req, res, next) {
  try {
    const { id } = req.params;
    const { latitude, longitude } = req.body;

    // Use Number.isFinite to properly validate numeric coordinates (allows 0)
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      return res.status(400).json({ error: 'Valid latitude and longitude coordinates required' });
    }

    const location = { latitude, longitude, timestamp: new Date().toISOString() };

    const result = await db.query(
      'UPDATE orders SET driver_location = $1 WHERE id = $2 RETURNING *',
      [JSON.stringify(location), id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json({
      success: true,
      order: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Cancel order
 */
async function cancelOrder(req, res, next) {
  try {
    const { id } = req.params;
    const clerkId = req.user.clerkId;

    // Get user ID
    const userResult = await db.query(
      'SELECT id FROM users WHERE clerk_id = $1',
      [clerkId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userId = userResult.rows[0].id;

    // Get current order
    const currentOrder = await db.query(
      'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (currentOrder.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // Check if order can be cancelled
    const order = currentOrder.rows[0];
    if (['completed', 'cancelled'].includes(order.status)) {
      return res.status(400).json({ error: 'Order cannot be cancelled' });
    }

    // Update to cancelled
    const result = await db.query(
      'UPDATE orders SET status = $1 WHERE id = $2 RETURNING *',
      ['cancelled', id]
    );

    // Log status change
    await db.query(
      `INSERT INTO order_status_history (order_id, old_status, new_status, changed_by, notes)
       VALUES ($1, $2, $3, $4, $5)`,
      [id, order.status, 'cancelled', userId, 'Cancelled by customer']
    );

    res.json({
      success: true,
      order: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createOrder,
  getUserOrders,
  getOrderById,
  updateOrderStatus,
  updateDriverLocation,
  cancelOrder
};

