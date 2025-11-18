# Happy Launderer API Documentation

Base URL: `http://localhost:3000/api` (Development)
Production: `https://your-app.railway.app/api`

All endpoints require authentication unless otherwise specified.

## Authentication

All authenticated endpoints require a Bearer token from Clerk in the Authorization header:

```
Authorization: Bearer <clerk_session_token>
```

---

## Endpoints

### Health Check

#### GET /health

Check if the API is running.

**Authentication:** Not required

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

---

## Authentication & Profile

### Create or Update Profile

#### POST /api/auth/profile

Create or update user profile information.

**Request Body:**
```json
{
  "name": "John Doe",
  "phone": "555-123-4567",
  "defaultAddress": {
    "street": "123 Main St",
    "city": "San Francisco",
    "state": "CA",
    "zipCode": "94102",
    "latitude": 37.7749,
    "longitude": -122.4194
  }
}
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "uuid",
    "clerk_id": "clerk_user_id",
    "name": "John Doe",
    "phone": "555-123-4567",
    "default_address": {...},
    "saved_addresses": [],
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
}
```

### Get Profile

#### GET /api/auth/profile

Get current user's profile.

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "uuid",
    "clerk_id": "clerk_user_id",
    "name": "John Doe",
    "phone": "555-123-4567",
    "default_address": {...},
    "saved_addresses": [],
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
}
```

### Update Profile

#### PUT /api/auth/profile

Update user profile information.

**Request Body:** Same as POST /api/auth/profile

**Response:** Same as POST /api/auth/profile

### Add Saved Address

#### POST /api/auth/profile/addresses

Add a new saved address.

**Request Body:**
```json
{
  "label": "Home",
  "street": "123 Main St",
  "city": "San Francisco",
  "state": "CA",
  "zipCode": "94102",
  "latitude": 37.7749,
  "longitude": -122.4194
}
```

**Response:**
```json
{
  "success": true,
  "user": {
    ...
    "saved_addresses": [
      {
        "label": "Home",
        "street": "123 Main St",
        ...
      }
    ]
  }
}
```

### Remove Saved Address

#### DELETE /api/auth/profile/addresses/:index

Remove a saved address by index.

**URL Parameters:**
- `index`: Integer - Index of the address to remove (0-based)

**Response:**
```json
{
  "success": true,
  "user": {...}
}
```

---

## Orders

### Create Order

#### POST /api/orders

Create a new laundry order.

**Request Body:**
```json
{
  "pickupAddress": {
    "street": "123 Main St",
    "city": "San Francisco",
    "state": "CA",
    "zipCode": "94102",
    "latitude": 37.7749,
    "longitude": -122.4194
  },
  "deliveryAddress": {
    "street": "456 Oak Ave",
    "city": "San Francisco",
    "state": "CA",
    "zipCode": "94103",
    "latitude": 37.7849,
    "longitude": -122.4294
  },
  "scheduledTime": "2024-01-15T10:00:00Z",
  "serviceType": "express",
  "itemCount": 5,
  "notes": "Please handle with care"
}
```

**Field Descriptions:**
- `pickupAddress`: Object - Pickup location
- `deliveryAddress`: Object - Delivery location
- `scheduledTime`: ISO 8601 datetime - When to pickup
- `serviceType`: Enum - "standard", "express", or "premium"
- `itemCount`: Integer - Number of items (optional, default: 0)
- `notes`: String - Special instructions (optional)

**Response:**
```json
{
  "success": true,
  "order": {
    "id": "uuid",
    "user_id": "uuid",
    "pickup_address": {...},
    "delivery_address": {...},
    "scheduled_time": "2024-01-15T10:00:00.000Z",
    "status": "pending",
    "service_type": "express",
    "item_count": 5,
    "price": 40.00,
    "driver_id": null,
    "driver_location": null,
    "notes": "Please handle with care",
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
}
```

### Get User Orders

#### GET /api/orders

Get all orders for the current user.

**Query Parameters:**
- `status`: String (optional) - Filter by status
- `limit`: Integer (optional, default: 50) - Max results
- `offset`: Integer (optional, default: 0) - Pagination offset

**Example:**
```
GET /api/orders?status=pending&limit=10
```

**Response:**
```json
{
  "success": true,
  "orders": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "status": "pending",
      ...
    }
  ],
  "count": 10
}
```

### Get Order Details

#### GET /api/orders/:id

Get detailed information about a specific order.

**URL Parameters:**
- `id`: UUID - Order ID

**Response:**
```json
{
  "success": true,
  "order": {
    "id": "uuid",
    "user_id": "uuid",
    "status": "in_laundry",
    ...
  },
  "statusHistory": [
    {
      "id": "uuid",
      "order_id": "uuid",
      "old_status": "picked_up",
      "new_status": "in_laundry",
      "changed_by": "uuid",
      "notes": null,
      "created_at": "2024-01-01T10:30:00.000Z"
    }
  ]
}
```

### Update Order Status

#### PUT /api/orders/:id

Update order status (driver/admin only).

**URL Parameters:**
- `id`: UUID - Order ID

**Request Body:**
```json
{
  "status": "picked_up",
  "notes": "Items collected"
}
```

**Status Options:**
- `pending`
- `picked_up`
- `in_laundry`
- `ready`
- `out_for_delivery`
- `completed`
- `cancelled`

**Response:**
```json
{
  "success": true,
  "order": {
    "id": "uuid",
    "status": "picked_up",
    ...
  }
}
```

### Update Driver Location

#### PUT /api/orders/:id/location

Update driver's current location (driver only).

**URL Parameters:**
- `id`: UUID - Order ID

**Request Body:**
```json
{
  "latitude": 37.7749,
  "longitude": -122.4194
}
```

**Response:**
```json
{
  "success": true,
  "order": {
    "id": "uuid",
    "driver_location": {
      "latitude": 37.7749,
      "longitude": -122.4194,
      "timestamp": "2024-01-01T10:00:00.000Z"
    },
    ...
  }
}
```

### Cancel Order

#### POST /api/orders/:id/cancel

Cancel an order.

**URL Parameters:**
- `id`: UUID - Order ID

**Response:**
```json
{
  "success": true,
  "order": {
    "id": "uuid",
    "status": "cancelled",
    ...
  }
}
```

**Note:** Orders cannot be cancelled if status is "completed" or "cancelled".

---

## Payments

### Process Payment

#### POST /api/payments/charge

Process payment for an order.

**Request Body:**
```json
{
  "orderId": "uuid",
  "paymentMethodId": "pm_stripe_payment_method_id"
}
```

**Response:**
```json
{
  "success": true,
  "payment": {
    "id": "uuid",
    "order_id": "uuid",
    "user_id": "uuid",
    "stripe_payment_id": "pi_stripe_payment_intent_id",
    "amount": 40.00,
    "status": "completed",
    "created_at": "2024-01-01T00:00:00.000Z"
  },
  "clientSecret": "pi_xxx_secret_xxx"
}
```

### Get Payment by Order ID

#### GET /api/payments/:orderId

Get payment details for a specific order.

**URL Parameters:**
- `orderId`: UUID - Order ID

**Response:**
```json
{
  "success": true,
  "payment": {
    "id": "uuid",
    "order_id": "uuid",
    "user_id": "uuid",
    "stripe_payment_id": "pi_xxx",
    "amount": 40.00,
    "status": "completed",
    "payment_method_id": "pm_xxx",
    "created_at": "2024-01-01T00:00:00.000Z"
  }
}
```

### Get All Payments

#### GET /api/payments

Get all payments for the current user.

**Response:**
```json
{
  "success": true,
  "payments": [
    {
      "id": "uuid",
      "order_id": "uuid",
      "amount": 40.00,
      "status": "completed",
      ...
    }
  ]
}
```

### Stripe Webhook

#### POST /api/payments/webhook

Webhook endpoint for Stripe events.

**Authentication:** Not required (verified with Stripe signature)

**Headers:**
- `stripe-signature`: Stripe webhook signature

---

## Pricing

### Calculate Price

#### POST /api/pricing/calculate

Calculate price for a service.

**Authentication:** Not required

**Request Body:**
```json
{
  "serviceType": "express",
  "itemCount": 5,
  "addons": ["stain_treatment", "ironing"]
}
```

**Addon Options:**
- `stain_treatment`: $10.00
- `delicate_care`: $15.00
- `ironing`: $20.00
- `dry_cleaning`: $25.00

**Response:**
```json
{
  "success": true,
  "pricing": {
    "serviceType": "express",
    "serviceName": "Express",
    "basePrice": 40.00,
    "addons": [
      {
        "name": "stain_treatment",
        "price": 10.00
      },
      {
        "name": "ironing",
        "price": 20.00
      }
    ],
    "totalPrice": 70.00,
    "description": "24-48 hours",
    "features": [
      "Wash and fold",
      "Premium detergent",
      "Next-day delivery",
      "Eco-friendly packaging"
    ]
  }
}
```

### Get Pricing Tiers

#### GET /api/pricing/tiers

Get all available service tiers and pricing.

**Authentication:** Not required

**Response:**
```json
{
  "success": true,
  "tiers": {
    "standard": {
      "name": "Standard",
      "basePrice": 25.00,
      "description": "3-5 business days",
      "features": [...]
    },
    "express": {
      "name": "Express",
      "basePrice": 40.00,
      "description": "24-48 hours",
      "features": [...]
    },
    "premium": {
      "name": "Premium",
      "basePrice": 60.00,
      "description": "Same day delivery",
      "features": [...]
    }
  }
}
```

---

## Error Responses

All endpoints may return error responses in the following format:

```json
{
  "error": "Error message",
  "details": ["Additional error details"]
}
```

### Common HTTP Status Codes

- `200 OK`: Success
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Missing or invalid authentication
- `403 Forbidden`: User doesn't have permission
- `404 Not Found`: Resource not found
- `409 Conflict`: Resource already exists
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

### Example Error Response

```json
{
  "error": "Validation error",
  "details": [
    "scheduledTime must be a valid ISO 8601 date",
    "serviceType must be one of: standard, express, premium"
  ]
}
```

---

## Rate Limiting

API endpoints are rate limited to 100 requests per 15 minutes per IP address.

If rate limit is exceeded, you'll receive a `429 Too Many Requests` response.

---

## Pagination

Endpoints that return lists support pagination via query parameters:

- `limit`: Maximum number of results (default: 50, max: 100)
- `offset`: Number of results to skip (default: 0)

Example:
```
GET /api/orders?limit=20&offset=40
```

---

## Date/Time Format

All dates and times are in ISO 8601 format with UTC timezone:

```
2024-01-15T10:00:00.000Z
```

---

## WebSocket Support (Future Enhancement)

Real-time order updates can be implemented via WebSocket connection:

```javascript
const ws = new WebSocket('wss://your-api.railway.app/ws');
ws.send(JSON.stringify({
  type: 'subscribe',
  orderId: 'uuid'
}));
```

---

## Testing

### Postman Collection

A Postman collection is available for testing all endpoints. Import the collection from `/docs/postman_collection.json`.

### Test Cards (Stripe)

Use these test cards in development:

- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`
- 3D Secure: `4000 0025 0000 3155`

---

## Support

For API issues or questions, please contact support or open an issue on GitHub.

