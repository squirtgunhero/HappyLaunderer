const Joi = require('joi');

// Pricing tiers
const PRICING_TIERS = {
  standard: {
    name: 'Standard',
    basePrice: 25.00,
    description: '3-5 business days',
    features: [
      'Wash and fold',
      'Basic detergent',
      'Standard packaging'
    ]
  },
  express: {
    name: 'Express',
    basePrice: 40.00,
    description: '24-48 hours',
    features: [
      'Wash and fold',
      'Premium detergent',
      'Next-day delivery',
      'Eco-friendly packaging'
    ]
  },
  premium: {
    name: 'Premium',
    basePrice: 60.00,
    description: 'Same day delivery',
    features: [
      'Wash and fold',
      'Luxury detergent',
      'Same-day delivery',
      'Hand washing available',
      'Premium packaging',
      'Stain treatment included'
    ]
  }
};

// Validation schema
const calculatePriceSchema = Joi.object({
  serviceType: Joi.string().valid('standard', 'express', 'premium').required(),
  itemCount: Joi.number().integer().min(0).default(0),
  addons: Joi.array().items(Joi.string()).default([])
});

/**
 * Calculate price for a service
 */
async function calculatePrice(req, res, next) {
  try {
    const { error, value } = calculatePriceSchema.validate(req.body);
    if (error) throw error;

    const { serviceType, itemCount, addons } = value;

    // Get base price
    const tier = PRICING_TIERS[serviceType];
    if (!tier) {
      return res.status(400).json({ error: 'Invalid service type' });
    }

    let totalPrice = tier.basePrice;

    // Add per-item charges (if applicable)
    // For now, using a simple model where the base price covers standard loads
    // Can be extended to charge per item

    // Add addon charges
    const addonPrices = {
      'stain_treatment': 10.00,
      'delicate_care': 15.00,
      'ironing': 20.00,
      'dry_cleaning': 25.00
    };

    addons.forEach(addon => {
      if (addonPrices[addon]) {
        totalPrice += addonPrices[addon];
      }
    });

    // Round to 2 decimal places
    totalPrice = Math.round(totalPrice * 100) / 100;

    res.json({
      success: true,
      pricing: {
        serviceType: serviceType,
        serviceName: tier.name,
        basePrice: tier.basePrice,
        addons: addons.map(addon => ({
          name: addon,
          price: addonPrices[addon] || 0
        })),
        totalPrice: totalPrice,
        description: tier.description,
        features: tier.features
      }
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Get all pricing tiers
 */
async function getPricingTiers(req, res) {
  res.json({
    success: true,
    tiers: PRICING_TIERS
  });
}

module.exports = {
  calculatePrice,
  getPricingTiers
};

