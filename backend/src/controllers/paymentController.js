const db = require('../config/database');
const Stripe = require('stripe');
const { clerkClient } = require('@clerk/clerk-sdk-node');
const Joi = require('joi');

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// Validation schema
const paymentSchema = Joi.object({
  orderId: Joi.string().uuid().required(),
  paymentMethodId: Joi.string().required()
});

/**
 * Process payment for an order
 */
async function processPayment(req, res, next) {
  try {
    const { error, value } = paymentSchema.validate(req.body);
    if (error) throw error;

    const { orderId, paymentMethodId } = value;
    const clerkId = req.user.clerkId;

    // Get user
    const userResult = await db.query(
      'SELECT id FROM users WHERE clerk_id = $1',
      [clerkId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userId = userResult.rows[0].id;

    // Get order
    const orderResult = await db.query(
      'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
      [orderId, userId]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const order = orderResult.rows[0];

    // Check if payment already exists
    const existingPayment = await db.query(
      'SELECT * FROM payments WHERE order_id = $1 AND status = $2',
      [orderId, 'completed']
    );

    if (existingPayment.rows.length > 0) {
      return res.status(400).json({ error: 'Order already paid' });
    }

    // Get Clerk user to retrieve Stripe customer ID
    const clerkUser = await clerkClient.users.getUser(clerkId);
    let customerId = clerkUser.publicMetadata?.stripeCustomerId;

    // Create Stripe customer if doesn't exist
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: req.user.email,
        metadata: {
          clerkId: clerkId
        }
      });
      customerId = customer.id;

      // Store customer ID in Clerk metadata
      await clerkClient.users.updateUserMetadata(clerkId, {
        publicMetadata: {
          ...(clerkUser.publicMetadata || {}),
          stripeCustomerId: customerId
        }
      });
    }

    // Create payment intent
    const amountInCents = Math.round(parseFloat(order.price) * 100);
    
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInCents,
      currency: 'usd',
      customer: customerId,
      payment_method: paymentMethodId,
      confirm: true,
      automatic_payment_methods: {
        enabled: true,
        allow_redirects: 'never'
      },
      metadata: {
        orderId: orderId,
        userId: userId,
        clerkId: clerkId
      }
    });

    // Create payment record
    const paymentResult = await db.query(
      `INSERT INTO payments (
        order_id,
        user_id,
        stripe_payment_id,
        stripe_payment_intent_id,
        amount,
        status,
        payment_method_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *`,
      [
        orderId,
        userId,
        paymentIntent.charges?.data?.[0]?.id || null, // Charge ID from the payment intent
        paymentIntent.id, // Payment Intent ID
        order.price,
        paymentIntent.status === 'succeeded' ? 'completed' : 'pending',
        paymentMethodId
      ]
    );

    res.json({
      success: true,
      payment: paymentResult.rows[0],
      clientSecret: paymentIntent.client_secret
    });
  } catch (error) {
    console.error('Payment error:', error);
    
    // Log failed payment
    if (req.body.orderId) {
      try {
        const userResult = await db.query(
          'SELECT id FROM users WHERE clerk_id = $1',
          [req.user.clerkId]
        );
        
        if (userResult.rows.length > 0) {
          await db.query(
            `INSERT INTO payments (
              order_id, user_id, amount, status, error_message
            ) VALUES ($1, $2, $3, $4, $5)`,
            [
              req.body.orderId,
              userResult.rows[0].id,
              0,
              'failed',
              error.message
            ]
          );
        }
      } catch (dbError) {
        console.error('Failed to log payment error:', dbError);
      }
    }
    
    next(error);
  }
}

/**
 * Get payment details by order ID
 */
async function getPaymentByOrderId(req, res, next) {
  try {
    const { orderId } = req.params;
    const clerkId = req.user.clerkId;

    // Get user
    const userResult = await db.query(
      'SELECT id FROM users WHERE clerk_id = $1',
      [clerkId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userId = userResult.rows[0].id;

    // Get payment
    const result = await db.query(
      'SELECT * FROM payments WHERE order_id = $1 AND user_id = $2',
      [orderId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    res.json({
      success: true,
      payment: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Get all payments for user
 */
async function getUserPayments(req, res, next) {
  try {
    const clerkId = req.user.clerkId;

    // Get user
    const userResult = await db.query(
      'SELECT id FROM users WHERE clerk_id = $1',
      [clerkId]
    );

    if (userResult.rows.length === 0) {
      return res.json({ success: true, payments: [] });
    }

    const userId = userResult.rows[0].id;

    // Get payments
    const result = await db.query(
      'SELECT * FROM payments WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );

    res.json({
      success: true,
      payments: result.rows
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Stripe webhook handler
 */
async function stripeWebhook(req, res, next) {
  try {
    const sig = req.headers['stripe-signature'];
    const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

    let event;

    try {
      event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
    } catch (err) {
      console.error('Webhook signature verification failed:', err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // Handle the event
    switch (event.type) {
      case 'payment_intent.succeeded':
        const paymentIntent = event.data.object;
        
        // Update payment status
        await db.query(
          'UPDATE payments SET status = $1 WHERE stripe_payment_intent_id = $2',
          ['completed', paymentIntent.id]
        );
        
        console.log('PaymentIntent succeeded:', paymentIntent.id);
        break;

      case 'payment_intent.payment_failed':
        const failedIntent = event.data.object;
        
        // Update payment status
        await db.query(
          `UPDATE payments 
           SET status = $1, error_message = $2 
           WHERE stripe_payment_intent_id = $3`,
          ['failed', failedIntent.last_payment_error?.message, failedIntent.id]
        );
        
        console.log('PaymentIntent failed:', failedIntent.id);
        break;

      default:
        console.log(`Unhandled event type ${event.type}`);
    }

    res.json({ received: true });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  processPayment,
  getPaymentByOrderId,
  getUserPayments,
  stripeWebhook
};

