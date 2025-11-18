require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

// Import routes
const authRoutes = require('./routes/auth');
const orderRoutes = require('./routes/orders');
const paymentRoutes = require('./routes/payments');
const pricingRoutes = require('./routes/pricing');

// Import middleware
const { verifyClerkToken } = require('./middleware/auth');
const errorHandler = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true
}));

// Logging
app.use(morgan('combined'));

// Stripe webhook - must be BEFORE rate limiting, body parsing, and authentication
// Needs raw body for signature verification and should not be rate limited
app.post(
  '/api/payments/webhook',
  express.raw({ type: 'application/json' }),
  require('./controllers/paymentController').stripeWebhook
);

// Rate limiting (applied AFTER webhook to exclude it from rate limits)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Body parsing (applied after webhook route to avoid parsing webhook body)
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/orders', verifyClerkToken, orderRoutes);
app.use('/api/payments', verifyClerkToken, paymentRoutes);
app.use('/api/pricing', pricingRoutes);

// Error handling
app.use(errorHandler);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Happy Launderer API running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;

