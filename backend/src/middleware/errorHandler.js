/**
 * Global error handling middleware
 */
function errorHandler(err, req, res, next) {
  console.error('Error:', err);

  // Joi validation errors
  if (err.isJoi) {
    return res.status(400).json({
      error: 'Validation error',
      details: err.details.map(d => d.message)
    });
  }

  // Database errors
  if (err.code) {
    switch (err.code) {
      case '23505': // Unique violation
        return res.status(409).json({ error: 'Resource already exists' });
      case '23503': // Foreign key violation
        return res.status(400).json({ error: 'Invalid reference' });
      case '23502': // Not null violation
        return res.status(400).json({ error: 'Missing required field' });
      default:
        console.error('Database error:', err.code, err.detail);
    }
  }

  // Stripe errors
  if (err.type && err.type.startsWith('Stripe')) {
    return res.status(400).json({ error: err.message });
  }

  // Default error
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    error: err.message || 'Internal server error'
  });
}

module.exports = errorHandler;

