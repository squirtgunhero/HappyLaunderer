const db = require('../config/database');
const Joi = require('joi');

// Validation schemas
const profileSchema = Joi.object({
  name: Joi.string().max(255),
  phone: Joi.string().max(50),
  defaultAddress: Joi.object({
    street: Joi.string().required(),
    city: Joi.string().required(),
    state: Joi.string().required(),
    zipCode: Joi.string().required(),
    latitude: Joi.number(),
    longitude: Joi.number()
  })
});

const addressSchema = Joi.object({
  label: Joi.string().required(),
  street: Joi.string().required(),
  city: Joi.string().required(),
  state: Joi.string().required(),
  zipCode: Joi.string().required(),
  latitude: Joi.number(),
  longitude: Joi.number()
});

/**
 * Create or update user profile
 */
async function upsertProfile(req, res, next) {
  try {
    const { error, value } = profileSchema.validate(req.body);
    if (error) throw error;

    const { name, phone, defaultAddress } = value;
    const clerkId = req.user.clerkId;

    // Check if user exists
    const existingUser = await db.query(
      'SELECT id FROM users WHERE clerk_id = $1',
      [clerkId]
    );

    let result;
    if (existingUser.rows.length > 0) {
      // Update existing user
      result = await db.query(
        `UPDATE users 
         SET name = COALESCE($1, name),
             phone = COALESCE($2, phone),
             default_address = COALESCE($3, default_address)
         WHERE clerk_id = $4
         RETURNING *`,
        [name, phone, defaultAddress ? JSON.stringify(defaultAddress) : null, clerkId]
      );
    } else {
      // Create new user
      result = await db.query(
        `INSERT INTO users (clerk_id, name, phone, default_address)
         VALUES ($1, $2, $3, $4)
         RETURNING *`,
        [clerkId, name, phone, defaultAddress ? JSON.stringify(defaultAddress) : null]
      );
    }

    res.json({
      success: true,
      user: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Get user profile
 */
async function getProfile(req, res, next) {
  try {
    const clerkId = req.user.clerkId;

    const result = await db.query(
      'SELECT * FROM users WHERE clerk_id = $1',
      [clerkId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    res.json({
      success: true,
      user: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Update user profile
 */
async function updateProfile(req, res, next) {
  try {
    const { error, value } = profileSchema.validate(req.body);
    if (error) throw error;

    const { name, phone, defaultAddress } = value;
    const clerkId = req.user.clerkId;

    const result = await db.query(
      `UPDATE users 
       SET name = COALESCE($1, name),
           phone = COALESCE($2, phone),
           default_address = COALESCE($3, default_address)
       WHERE clerk_id = $4
       RETURNING *`,
      [name, phone, defaultAddress ? JSON.stringify(defaultAddress) : null, clerkId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    res.json({
      success: true,
      user: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Add saved address
 */
async function addAddress(req, res, next) {
  try {
    const { error, value } = addressSchema.validate(req.body);
    if (error) throw error;

    const clerkId = req.user.clerkId;

    const result = await db.query(
      `UPDATE users 
       SET saved_addresses = saved_addresses || jsonb_build_array($1::jsonb)
       WHERE clerk_id = $2
       RETURNING *`,
      [JSON.stringify(value), clerkId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    res.json({
      success: true,
      user: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Remove saved address by index
 */
async function removeAddress(req, res, next) {
  try {
    const { index } = req.params;
    const clerkId = req.user.clerkId;

    // Validate index parameter
    const parsedIndex = parseInt(index, 10);
    if (isNaN(parsedIndex) || parsedIndex < 0) {
      return res.status(400).json({ 
        error: 'Invalid index parameter',
        details: ['Index must be a non-negative integer']
      });
    }

    const result = await db.query(
      `UPDATE users 
       SET saved_addresses = COALESCE(
         (
           SELECT jsonb_agg(elem)
           FROM jsonb_array_elements(saved_addresses) WITH ORDINALITY arr(elem, idx)
           WHERE idx - 1 != $1
         ),
         '[]'::jsonb
       )
       WHERE clerk_id = $2
       RETURNING *`,
      [parsedIndex, clerkId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    res.json({
      success: true,
      user: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  upsertProfile,
  getProfile,
  updateProfile,
  addAddress,
  removeAddress
};

