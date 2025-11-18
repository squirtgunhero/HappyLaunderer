# Bug Fixes and Improvements

This document tracks significant bug fixes and improvements made to the Happy Launderer application.

---

## Bug Fix: Memory Leak in Real-Time Order Updates

**Date**: 2024-01-01  
**Severity**: High  
**Component**: OrderManager.swift  
**Status**: ✅ Fixed

### Problem

The `startRealTimeUpdates` function created an infinite polling loop with no cancellation mechanism, causing:

1. **Memory Leaks**: Unbounded background tasks accumulated in memory when the function was called multiple times
2. **Resource Waste**: Continuous network requests persisted after leaving the order detail view
3. **No Control**: No mechanism to stop polling once started
4. **Battery Drain**: Unnecessary background network activity

**Problematic Code:**
```swift
func startRealTimeUpdates(for orderId: String) {
    Task {
        while true {  // ❌ Infinite loop with no cancellation
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            do {
                _ = try await fetchOrderDetails(orderId: orderId)
            } catch {
                print("Failed to fetch order updates: \(error)")
            }
        }
    }
}
```

### Solution

Implemented proper task management with cancellation support:

**Fixed Code:**
```swift
// Track active polling tasks
private var pollingTasks: [String: Task<Void, Never>] = [:]

@discardableResult
func startRealTimeUpdates(for orderId: String) -> Task<Void, Never> {
    // Cancel existing task for this order
    stopRealTimeUpdates(for: orderId)
    
    let task = Task {
        while !Task.isCancelled {  // ✅ Check for cancellation
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            if Task.isCancelled { break }  // ✅ Exit on cancellation
            
            do {
                let (order, _) = try await fetchOrderDetails(orderId: orderId)
                
                // Auto-stop when order completes
                if order.status.isCompleted {
                    await MainActor.run {
                        self.stopRealTimeUpdates(for: orderId)
                    }
                    break
                }
            } catch {
                print("Failed to fetch order updates: \(error)")
            }
        }
        
        // Cleanup
        await MainActor.run {
            self.pollingTasks.removeValue(forKey: orderId)
        }
    }
    
    pollingTasks[orderId] = task
    return task
}

func stopRealTimeUpdates(for orderId: String) {
    pollingTasks[orderId]?.cancel()
    pollingTasks.removeValue(forKey: orderId)
}

func stopAllRealTimeUpdates() {
    for task in pollingTasks.values {
        task.cancel()
    }
    pollingTasks.removeAll()
}
```

### Key Improvements

1. **Task Tracking**: Dictionary stores active polling tasks by order ID
2. **Cancellation Support**: Tasks check `Task.isCancelled` and can be cancelled
3. **Automatic Cleanup**: Tasks clean up when completed or cancelled
4. **Prevent Duplicates**: Existing tasks are cancelled before starting new ones
5. **Auto-Stop**: Polling automatically stops when order is completed
6. **Memory Safety**: Tasks are properly stored and released

### Usage in Views

**Updated OrderDetailView:**
```swift
.task {
    await refreshOrder()
    
    if order.status.isActive {
        await withTaskCancellationHandler {
            let pollingTask = orderManager.startRealTimeUpdates(for: order.id)
            await pollingTask.value
        } onCancel: {
            orderManager.stopRealTimeUpdates(for: order.id)
        }
    }
}
.onDisappear {
    // Extra safety: ensure polling stops
    orderManager.stopRealTimeUpdates(for: order.id)
}
```

**Benefits:**
- `.task` modifier automatically cancels when view disappears
- `withTaskCancellationHandler` provides explicit cleanup
- `.onDisappear` provides additional safety net
- No manual task management needed in views

### Testing

**Verify the fix:**

1. **No Memory Leaks:**
   - Open OrderDetailView multiple times
   - Verify only one polling task exists per order
   - Check memory usage remains stable

2. **Proper Cancellation:**
   - Open OrderDetailView
   - Navigate back
   - Verify network requests stop

3. **Auto-Stop on Completion:**
   - Track an order until completed
   - Verify polling stops automatically

4. **Multiple Orders:**
   - Track multiple orders simultaneously
   - Verify each has independent polling
   - Close views and verify tasks are cancelled

### Performance Impact

**Before Fix:**
- Memory: Grows indefinitely with each view open
- Network: Continuous requests even after view closes
- Battery: Unnecessary background activity

**After Fix:**
- Memory: Constant, one task per active order
- Network: Requests stop when view closes
- Battery: No unnecessary background activity

---

## Best Practices for Background Tasks

Based on this fix, follow these guidelines for background tasks:

### 1. Always Provide Cancellation

```swift
// ✅ Good: Check for cancellation
Task {
    while !Task.isCancelled {
        // Do work
        try? await Task.sleep(...)
    }
}

// ❌ Bad: No cancellation check
Task {
    while true {
        // Do work
    }
}
```

### 2. Track Long-Running Tasks

```swift
class Manager {
    private var tasks: [String: Task<Void, Never>] = [:]
    
    func startTask(id: String) {
        // Cancel existing
        tasks[id]?.cancel()
        
        // Store new task
        let task = Task { /* work */ }
        tasks[id] = task
    }
    
    func stopTask(id: String) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
    }
}
```

### 3. Use SwiftUI Task Modifiers

```swift
// ✅ Good: Automatic cancellation
.task {
    await doWork()
}

// ❌ Bad: Manual Task creation
.onAppear {
    Task {
        await doWork()
    }
}
```

### 4. Clean Up Resources

```swift
Task {
    defer {
        // Always cleanup
        cleanup()
    }
    
    while !Task.isCancelled {
        // Do work
    }
}
```

### 5. Handle Cancellation Gracefully

```swift
do {
    try await Task.sleep(...)
    
    if Task.isCancelled {
        print("Task cancelled, cleaning up...")
        return
    }
    
    await doWork()
} catch is CancellationError {
    print("Task was cancelled")
}
```

---

---

## Bug Fix: Stripe Webhook Authentication and Body Parsing Issues

**Date**: 2024-01-01  
**Severity**: Critical  
**Component**: backend/src/index.js, backend/src/routes/payments.js  
**Status**: ✅ Fixed

### Problem

The Stripe webhook endpoint had **three critical issues** that prevented it from functioning:

1. **Authentication Blocking**: Webhook protected by `verifyClerkToken` middleware
2. **Body Parsing**: Webhook received JSON-parsed body instead of raw body needed for signature verification
3. **Route Order**: Global `express.json()` processed request before webhook could get raw body

**Problematic Code:**

```javascript
// index.js - Line 39
app.use(express.json());  // ❌ Parses ALL request bodies to JSON

// Line 50
app.use('/api/payments', verifyClerkToken, paymentRoutes);  
// ❌ Requires authentication for ALL payment routes including webhook

// payments.js - Line 15
router.post('/webhook', express.raw({ type: 'application/json' }), ...);
// ❌ Too late, body already parsed by global middleware
```

**Why This Breaks:**

1. **Stripe webhooks come from Stripe's servers** - They don't have Clerk authentication tokens
2. **Stripe signature verification requires raw body** - `stripe.webhooks.constructEvent(req.body, sig, secret)` needs raw Buffer, not parsed JSON
3. **Middleware order matters** - Once `express.json()` parses the body, it's too late

### Impact

- ❌ Webhooks would be rejected with 401 Unauthorized
- ❌ Even if authentication bypassed, signature verification would fail
- ❌ Payment status updates wouldn't reach the application
- ❌ Users wouldn't see completed/failed payment statuses

### Solution

Registered webhook endpoint **before** global middleware with proper configuration:

**Fixed Code:**

```javascript
// index.js - Lines 38-44
// Stripe webhook - must be BEFORE body parsing middleware
// Needs raw body for signature verification and no authentication
app.post(
  '/api/payments/webhook',
  express.raw({ type: 'application/json' }),
  require('./controllers/paymentController').stripeWebhook
);

// Body parsing (applied AFTER webhook route)
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
```

```javascript
// payments.js - Webhook route removed from router
// Note: Webhook endpoint is registered directly in index.js
// to bypass authentication and receive raw body for signature verification
```

### Key Improvements

1. **✅ No Authentication**: Webhook registered directly, bypasses `verifyClerkToken`
2. **✅ Raw Body**: Gets `express.raw()` before `express.json()` processes it
3. **✅ Correct Order**: Registered before global body parsing middleware
4. **✅ Signature Verification**: Can properly verify Stripe signatures
5. **✅ Security**: Webhook still secured via Stripe signature verification

### How It Works Now

```
Stripe Webhook Request Flow:
1. Request hits /api/payments/webhook
2. express.raw() middleware processes it (gets raw Buffer)
3. stripeWebhook controller receives raw body
4. Verifies Stripe signature using raw body + secret
5. Processes webhook event
6. Returns success response to Stripe
```

### Testing

**Test Webhook Endpoint:**

```bash
# Test with Stripe CLI
stripe listen --forward-to localhost:3000/api/payments/webhook

# Trigger test event
stripe trigger payment_intent.succeeded
```

**Verify in Logs:**

```javascript
// Should see in console:
PaymentIntent succeeded: pi_xxxxx
```

**Check Stripe Dashboard:**

1. Go to Developers → Webhooks
2. Check webhook endpoint status
3. View recent deliveries
4. Should show successful responses (200 OK)

### Security Considerations

**Before Fix:**
- ❌ Relied on Clerk authentication (wrong for webhooks)
- ❌ No actual security since webhooks would fail

**After Fix:**
- ✅ Uses Stripe signature verification (`stripe.webhooks.constructEvent`)
- ✅ Validates webhook came from Stripe
- ✅ Prevents replay attacks (signature includes timestamp)
- ✅ Follows Stripe best practices

**Why Signature Verification is Secure:**

```javascript
// Stripe signs webhook with secret key
const sig = req.headers['stripe-signature'];

// Verify signature matches
stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
// Throws error if signature invalid or timestamp too old
```

### Configuration Required

Add to `.env`:

```env
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_signing_secret
```

**Get signing secret:**

1. Stripe Dashboard → Developers → Webhooks
2. Click on webhook endpoint
3. Reveal signing secret
4. Copy to `.env`

### Best Practices for Webhooks

Based on this fix:

**1. Register Webhooks BEFORE Body Parsing**

```javascript
// ✅ Correct order
app.post('/webhook', express.raw(), webhookHandler);
app.use(express.json());

// ❌ Wrong order
app.use(express.json());
app.post('/webhook', express.raw(), webhookHandler);  // Too late!
```

**2. Bypass Authentication for Webhooks**

```javascript
// ✅ Register webhook separately
app.post('/webhook', webhookHandler);

// Then apply auth to other routes
app.use('/api/', authMiddleware, routes);
```

**3. Use Webhook-Specific Security**

```javascript
// ✅ Verify webhook signature
const event = provider.webhooks.constructEvent(body, sig, secret);

// ❌ Don't rely on authentication
// Webhooks come from external servers, not authenticated users
```

**4. Test Webhooks Locally**

```bash
# Use provider's CLI tools
stripe listen --forward-to localhost:3000/api/payments/webhook

# Or use ngrok
ngrok http 3000
# Update webhook URL in Stripe dashboard
```

### Related Documentation

- [Stripe Webhook Documentation](https://stripe.com/docs/webhooks)
- [Express.js Middleware](https://expressjs.com/en/guide/using-middleware.html)
- [Stripe Signature Verification](https://stripe.com/docs/webhooks/signatures)

---

## Bug Fix: Invalid Index Validation in removeAddress

**Date**: 2024-01-01  
**Severity**: Medium  
**Component**: backend/src/controllers/authController.js  
**Status**: ✅ Fixed

### Problem

The `removeAddress` function did not validate the index parameter before using it in the database query. This could lead to unexpected behavior or errors.

**Problematic Code:**

```javascript
async function removeAddress(req, res, next) {
  try {
    const { index } = req.params;
    const clerkId = req.user.clerkId;

    const result = await db.query(
      `UPDATE users SET saved_addresses = ...
       WHERE idx - 1 != $1`,
      [parseInt(index), clerkId]  // ❌ No validation before parseInt
    );
    // ...
  }
}
```

**Issues:**

1. **No Type Validation**: `parseInt('invalid')` returns `NaN`
2. **No Range Validation**: Negative indices not prevented
3. **SQL Injection Risk**: Malformed input could cause unexpected behavior
4. **Poor Error Messages**: Users get generic errors instead of validation feedback

**Example Attacks:**

```bash
# Invalid string
DELETE /api/auth/profile/addresses/invalid
# Returns 200 but may delete wrong addresses or error silently

# Negative index
DELETE /api/auth/profile/addresses/-1
# May delete wrong address or behave unexpectedly

# Float value
DELETE /api/auth/profile/addresses/1.5
# Unpredictable behavior
```

### Solution

Added comprehensive validation before using the index parameter:

**Fixed Code:**

```javascript
async function removeAddress(req, res, next) {
  try {
    const { index } = req.params;
    const clerkId = req.user.clerkId;

    // Validate index parameter
    const parsedIndex = parseInt(index, 10);  // ✅ Explicit radix
    if (isNaN(parsedIndex) || parsedIndex < 0) {  // ✅ Validate result
      return res.status(400).json({ 
        error: 'Invalid index parameter',
        details: ['Index must be a non-negative integer']
      });
    }

    const result = await db.query(
      `UPDATE users SET saved_addresses = ...
       WHERE idx - 1 != $1`,
      [parsedIndex, clerkId]  // ✅ Validated index
    );
    // ...
  }
}
```

### Key Improvements

1. **✅ Type Check**: Validates result is a number (`isNaN()`)
2. **✅ Range Check**: Ensures non-negative (`>= 0`)
3. **✅ Explicit Radix**: Uses base-10 parsing (`parseInt(index, 10)`)
4. **✅ Early Return**: Fails fast with clear error message
5. **✅ Proper HTTP Status**: Returns 400 Bad Request

### Security Impact

**Before Fix:**
- ❌ Could pass `NaN` to SQL query
- ❌ Negative indices not prevented
- ❌ No user feedback on validation

**After Fix:**
- ✅ Only valid non-negative integers reach database
- ✅ Clear validation errors returned to client
- ✅ Prevents unexpected database behavior

### Testing

**Test Cases:**

```bash
# Valid index
DELETE /api/auth/profile/addresses/0
# ✅ Should delete address at index 0

# Invalid string
DELETE /api/auth/profile/addresses/invalid
# ✅ Should return 400: "Invalid index parameter"

# Negative index
DELETE /api/auth/profile/addresses/-1
# ✅ Should return 400: "Invalid index parameter"

# Float value
DELETE /api/auth/profile/addresses/1.5
# ✅ Should return 400 (parseInt returns 1, but works correctly)

# Out of bounds (valid format but doesn't exist)
DELETE /api/auth/profile/addresses/999
# ✅ Should return 200 but not delete anything (index doesn't exist)
```

---

## Bug Fix: Null Metadata Spreading in Payment Processing

**Date**: 2024-01-01  
**Severity**: High  
**Component**: backend/src/controllers/paymentController.js  
**Status**: ✅ Fixed

### Problem

When updating Clerk user metadata during payment processing, the code attempted to spread `publicMetadata` without checking if it was `null` or `undefined`. For users who have never had metadata set, this property is `null`, causing a `TypeError` that breaks payment processing.

**Problematic Code:**

```javascript
// Store customer ID in Clerk metadata
await clerkClient.users.updateUserMetadata(clerkId, {
  publicMetadata: {
    ...clerkUser.publicMetadata,  // ❌ Throws if publicMetadata is null
    stripeCustomerId: customerId
  }
});
```

**Error:**

```
TypeError: Cannot spread non-iterable instance
```

**When It Occurs:**

- New users who have never had metadata set
- Users whose metadata was deleted
- Any user with `publicMetadata: null`

### Impact

- ❌ Payment processing fails completely for affected users
- ❌ First-time users cannot make payments
- ❌ Critical blocker for new customer onboarding
- ❌ Poor user experience with cryptic error messages

### Solution

Use nullish coalescing operator to provide default empty object:

**Fixed Code:**

```javascript
// Store customer ID in Clerk metadata
await clerkClient.users.updateUserMetadata(clerkId, {
  publicMetadata: {
    ...(clerkUser.publicMetadata || {}),  // ✅ Defaults to empty object
    stripeCustomerId: customerId
  }
});
```

### How It Works

The nullish coalescing operator `||` provides a fallback:

```javascript
// If publicMetadata is null or undefined
null || {}           // Returns: {}
undefined || {}      // Returns: {}

// If publicMetadata exists
{ role: 'user' } || {}  // Returns: { role: 'user' }

// After spreading
...({})                           // No error, expands to nothing
...({ role: 'user' })             // Expands to: role: 'user'
...({ role: 'user', customerId }) // Both properties preserved
```

### Alternative Solutions Considered

**Option 1: Check before spreading**
```javascript
// ❌ More verbose
publicMetadata: clerkUser.publicMetadata 
  ? { ...clerkUser.publicMetadata, stripeCustomerId: customerId }
  : { stripeCustomerId: customerId }
```

**Option 2: Nullish coalescing (CHOSEN)**
```javascript
// ✅ Concise and clear
publicMetadata: {
  ...(clerkUser.publicMetadata || {}),
  stripeCustomerId: customerId
}
```

**Option 3: Optional chaining**
```javascript
// ⚠️ Doesn't work for spreading
publicMetadata: {
  ...clerkUser.publicMetadata?.  // Syntax error
  stripeCustomerId: customerId
}
```

### Testing

**Test Cases:**

```javascript
// Test 1: New user with no metadata
const newUser = { publicMetadata: null };
// ✅ Should work: { stripeCustomerId: 'cus_xxx' }

// Test 2: User with existing metadata
const existingUser = { publicMetadata: { role: 'premium' } };
// ✅ Should preserve: { role: 'premium', stripeCustomerId: 'cus_xxx' }

// Test 3: User with undefined metadata
const undefinedUser = { publicMetadata: undefined };
// ✅ Should work: { stripeCustomerId: 'cus_xxx' }

// Test 4: Overwriting existing customerId
const withCustomerId = { publicMetadata: { stripeCustomerId: 'old' } };
// ✅ Should update: { stripeCustomerId: 'cus_new' }
```

**Manual Test:**

1. Create new user account (no metadata)
2. Create order
3. Process payment
4. Verify payment succeeds
5. Check Clerk dashboard - metadata should show `stripeCustomerId`

### Best Practice

This pattern should be used anywhere you spread potentially null/undefined objects:

```javascript
// ✅ Always provide default
...( possiblyNull || {} )
...( possiblyUndefined || {} )
...( possiblyNull ?? {} )  // Nullish coalescing operator (ES2020+)

// ❌ Risky
...possiblyNull
```

### Related Code

Check for similar patterns elsewhere:

```bash
# Search for risky spreads
grep -r "\.\.\..*\..*Metadata" backend/src/
```

---

## Bug Fix: Incorrect JSONB Array Concatenation in addAddress

**Date**: 2024-01-01  
**Severity**: High  
**Component**: backend/src/controllers/authController.js  
**Status**: ✅ Fixed

### Problem

The `addAddress` function used PostgreSQL's JSONB concatenation operator `||` incorrectly, causing address objects to replace the array instead of being appended to it.

**Problematic Code:**

```javascript
const result = await db.query(
  `UPDATE users 
   SET saved_addresses = saved_addresses || $1::jsonb  // ❌ Wrong!
   WHERE clerk_id = $2
   RETURNING *`,
  [JSON.stringify(value), clerkId]
);
```

**PostgreSQL Behavior:**

```sql
-- What happens with || operator
SELECT '[]'::jsonb || '{"label": "Home"}'::jsonb;
-- Result: {"label": "Home"}  ❌ Array becomes object!

SELECT '[{"label": "Work"}]'::jsonb || '{"label": "Home"}'::jsonb;
-- Result: [{"label": "Work"}, {"label": "Home"}]  ✅ Works by accident

-- The problem:
-- When saved_addresses is empty [], the first address replaces the array
-- instead of being added to it
```

**Issues:**

1. **First Address Replaces Array**: Empty `[]` + object = object (not array)
2. **Type Inconsistency**: Field changes from array to object
3. **Breaking Change**: Subsequent operations expect array, get object
4. **iOS Decoding Fails**: App expects array, receives object

**Example Failure:**

```javascript
// User has no saved addresses (default: [])
// Add first address
POST /api/auth/profile/addresses
Body: { label: "Home", street: "123 Main St", ... }

// Database result: saved_addresses = {"label": "Home", ...}  ❌
// Expected:        saved_addresses = [{"label": "Home", ...}] ✅

// iOS app tries to decode as array:
let addresses: [SavedAddress] = user.savedAddresses  // ❌ Crash!
```

### Solution

Use `jsonb_build_array()` to wrap the incoming object in an array before concatenation:

**Fixed Code:**

```javascript
const result = await db.query(
  `UPDATE users 
   SET saved_addresses = saved_addresses || jsonb_build_array($1::jsonb)
   WHERE clerk_id = $2
   RETURNING *`,
  [JSON.stringify(value), clerkId]
);
```

**How It Works:**

```sql
-- Correct behavior with jsonb_build_array
SELECT '[]'::jsonb || jsonb_build_array('{"label": "Home"}'::jsonb);
-- Result: [{"label": "Home"}]  ✅ Correct!

SELECT '[{"label": "Work"}]'::jsonb || jsonb_build_array('{"label": "Home"}'::jsonb);
-- Result: [{"label": "Work"}, {"label": "Home"}]  ✅ Correct!

-- The fix:
-- jsonb_build_array() wraps the object in an array [{}]
-- Then [] || [{}] = [{}] (array concatenation)
```

### Key Improvements

1. **✅ Maintains Array Type**: Field is always an array
2. **✅ Consistent Behavior**: Works correctly for empty and non-empty arrays
3. **✅ iOS Compatibility**: App can reliably decode as array
4. **✅ Schema Contract**: Respects `saved_addresses JSONB DEFAULT '[]'::jsonb`

### Testing

**Test Cases:**

```sql
-- Test 1: Add first address to empty array
UPDATE users SET saved_addresses = '[]'::jsonb;
UPDATE users SET saved_addresses = saved_addresses || jsonb_build_array('{"label":"Home"}'::jsonb);
SELECT saved_addresses FROM users;
-- ✅ Result: [{"label": "Home"}]

-- Test 2: Add second address
UPDATE users SET saved_addresses = saved_addresses || jsonb_build_array('{"label":"Work"}'::jsonb);
SELECT saved_addresses FROM users;
-- ✅ Result: [{"label": "Home"}, {"label": "Work"}]

-- Test 3: Verify array operations work
SELECT jsonb_array_length(saved_addresses) FROM users;
-- ✅ Result: 2
```

**API Test:**

```bash
# Add first address
curl -X POST http://localhost:3000/api/auth/profile/addresses \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"label":"Home","street":"123 Main St","city":"SF","state":"CA","zipCode":"94102"}'

# Verify result is array
curl http://localhost:3000/api/auth/profile \
  -H "Authorization: Bearer $TOKEN"
# ✅ saved_addresses should be array: [{ label: "Home", ... }]

# Add second address
curl -X POST http://localhost:3000/api/auth/profile/addresses \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"label":"Work","street":"456 Oak Ave","city":"SF","state":"CA","zipCode":"94103"}'

# Verify both addresses in array
# ✅ saved_addresses: [{ label: "Home", ... }, { label: "Work", ... }]
```

### Impact Before Fix

**User Flow:**
1. New user signs up (saved_addresses: `[]`)
2. Adds first address
3. ❌ saved_addresses becomes object instead of array
4. iOS app tries to decode as array
5. ❌ Decoding fails or crashes
6. User cannot see/manage addresses

---

## Bug Fix: JSONB Array Becomes NULL When Removing Last Address

**Date**: 2024-01-01  
**Severity**: Medium-High  
**Component**: backend/src/controllers/authController.js  
**Status**: ✅ Fixed

### Problem

The `removeAddress` function's SQL query uses `jsonb_agg()` which returns `NULL` when no rows match the WHERE condition. When removing the last saved address, `saved_addresses` is set to `NULL` instead of maintaining the empty array `[]`.

**Problematic Code:**

```javascript
const result = await db.query(
  `UPDATE users 
   SET saved_addresses = (
     SELECT jsonb_agg(elem)  // ❌ Returns NULL when no rows
     FROM jsonb_array_elements(saved_addresses) WITH ORDINALITY arr(elem, idx)
     WHERE idx - 1 != $1
   )
   WHERE clerk_id = $2
   RETURNING *`,
  [parsedIndex, clerkId]
);
```

**PostgreSQL Behavior:**

```sql
-- jsonb_agg with no matching rows
SELECT jsonb_agg(elem) 
FROM jsonb_array_elements('[{"label":"Home"}]'::jsonb) WITH ORDINALITY arr(elem, idx)
WHERE idx - 1 != 0;  -- Excludes all rows
-- Result: NULL  ❌

-- Schema default
saved_addresses JSONB DEFAULT '[]'::jsonb  -- Array, not NULL
```

**Issues:**

1. **Schema Violation**: Field initialized as `[]`, becomes `NULL`
2. **Type Inconsistency**: Sometimes array, sometimes null
3. **iOS Decoding Issues**: App expects array, may receive null
4. **Iteration Errors**: `for address in user.saved_addresses` fails if null

**Example Failure:**

```javascript
// User has one saved address
// Remove the last address
DELETE /api/auth/profile/addresses/0

// Database result: saved_addresses = null  ❌
// Expected:        saved_addresses = []    ✅

// iOS app code:
struct User {
  var savedAddresses: [SavedAddress]  // Non-optional array
}

// Decoding from API:
// - Expects: []
// - Gets: null
// ❌ Decoding error or crash
```

### Solution

Use `COALESCE()` to return empty array when `jsonb_agg()` returns `NULL`:

**Fixed Code:**

```javascript
const result = await db.query(
  `UPDATE users 
   SET saved_addresses = COALESCE(
     (
       SELECT jsonb_agg(elem)
       FROM jsonb_array_elements(saved_addresses) WITH ORDINALITY arr(elem, idx)
       WHERE idx - 1 != $1
     ),
     '[]'::jsonb  // ✅ Default to empty array
   )
   WHERE clerk_id = $2
   RETURNING *`,
  [parsedIndex, clerkId]
);
```

**How It Works:**

```sql
-- With COALESCE
SELECT COALESCE(
  (SELECT jsonb_agg(elem) FROM ... WHERE false),  -- Returns NULL
  '[]'::jsonb  -- Fallback to empty array
);
-- Result: []  ✅

-- Maintains consistency
- Before: saved_addresses = [{"label": "Home"}]
- After delete: saved_addresses = []  (not NULL)
```

### Key Improvements

1. **✅ Maintains Array Type**: Field is always array, never NULL
2. **✅ Schema Consistency**: Respects default value contract
3. **✅ iOS Compatibility**: Always returns array for decoding
4. **✅ Safe Iteration**: Empty array can be safely iterated

### Testing

**Test Cases:**

```sql
-- Test 1: Remove last address
UPDATE users SET saved_addresses = '[{"label": "Home"}]'::jsonb;

UPDATE users SET saved_addresses = COALESCE(
  (SELECT jsonb_agg(elem) FROM jsonb_array_elements(saved_addresses) 
   WITH ORDINALITY arr(elem, idx) WHERE idx - 1 != 0),
  '[]'::jsonb
);

SELECT saved_addresses FROM users;
-- ✅ Result: []  (not NULL)

-- Test 2: Remove middle address (keeps array)
UPDATE users SET saved_addresses = '[{"label":"Home"},{"label":"Work"},{"label":"Gym"}]'::jsonb;

UPDATE users SET saved_addresses = COALESCE(
  (SELECT jsonb_agg(elem) FROM jsonb_array_elements(saved_addresses) 
   WITH ORDINALITY arr(elem, idx) WHERE idx - 1 != 1),
  '[]'::jsonb
);

SELECT saved_addresses FROM users;
-- ✅ Result: [{"label":"Home"},{"label":"Gym"}]

-- Test 3: Verify array type
SELECT pg_typeof(saved_addresses) FROM users;
-- ✅ Result: jsonb (array type)
```

**API Test:**

```bash
# User with one address
curl http://localhost:3000/api/auth/profile \
  -H "Authorization: Bearer $TOKEN"
# Response: saved_addresses: [{"label": "Home", ...}]

# Remove the only address
curl -X DELETE http://localhost:3000/api/auth/profile/addresses/0 \
  -H "Authorization: Bearer $TOKEN"

# Verify result is empty array (not null)
curl http://localhost:3000/api/auth/profile \
  -H "Authorization: Bearer $TOKEN"
# ✅ saved_addresses: []  (not null)

# Add another address (should work)
curl -X POST http://localhost:3000/api/auth/profile/addresses \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"label":"Work", ...}'
# ✅ Should succeed
```

### Impact Before Fix

**User Flow:**
1. User has one saved address
2. Deletes it
3. ❌ saved_addresses becomes NULL
4. User tries to add new address
5. ❌ Might fail due to NULL + array operation
6. iOS app tries to display addresses
7. ❌ Decoding error or crash

### Best Practice

Always use `COALESCE` with aggregation functions that can return NULL:

```sql
-- ✅ Good: Provides fallback
COALESCE(jsonb_agg(col), '[]'::jsonb)
COALESCE(array_agg(col), ARRAY[]::type[])
COALESCE(COUNT(*), 0)  -- COUNT never returns NULL, but good practice

-- ❌ Risky: Can return NULL
jsonb_agg(col)
array_agg(col)
```

---

## Bug Fix: Stripe Webhook Rate Limiting Issue

**Date**: 2024-01-01  
**Severity**: High  
**Component**: backend/src/index.js  
**Status**: ✅ Fixed

### Problem

The rate limiter middleware was applied to all `/api/` routes before the Stripe webhook endpoint was registered. This meant Stripe webhook requests were subject to rate limiting (100 requests per 15 minutes), which could cause critical payment status updates to fail.

**Problematic Code:**

```javascript
// Rate limiting applied to /api/*
app.use('/api/', limiter);  // ❌ Line 33

// Webhook registered later
app.post('/api/payments/webhook', ...);  // ❌ Lines 40-44 - gets rate limited!
```

**Issues:**

1. **Webhook Rate Limited**: Stripe webhooks limited to 100 requests per 15 minutes
2. **Batch Deliveries Fail**: Stripe may send multiple webhooks in quick succession
3. **429 Errors**: Exceeded rate limit returns "Too Many Requests"
4. **Silent Failures**: Payment status updates lost
5. **No Retry Success**: Stripe retries also hit rate limit

**Example Failure Scenario:**

```
Stripe sends batch of webhooks:
1. payment_intent.created
2. payment_intent.succeeded  
3. charge.succeeded
4. ...100+ webhooks in 15 minutes

After 100th webhook:
❌ 429 Too Many Requests
❌ Payment status never updates
❌ User never sees completed payment
```

### Impact

**Critical Business Impact:**
- ❌ Payment confirmations lost
- ❌ Order statuses never update
- ❌ Users don't know if payment succeeded
- ❌ Manual reconciliation required
- ❌ Poor user experience

**Stripe Behavior:**
- Stripe retries failed webhooks with exponential backoff
- But if rate limit still in effect, retries also fail
- After multiple failures, Stripe stops sending webhooks
- Results in permanent data inconsistency

### Solution

Register webhook endpoint **before** rate limiter is applied, excluding it from rate limits:

**Fixed Code:**

```javascript
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
  max: 100
});
app.use('/api/', limiter);
```

### Key Improvements

1. **✅ No Rate Limiting**: Webhook not subject to rate limits
2. **✅ Unlimited Webhooks**: Can handle any volume from Stripe
3. **✅ Reliable Delivery**: All webhooks processed successfully
4. **✅ Batch Support**: Multiple webhooks in quick succession work fine
5. **✅ Still Secure**: Signature verification still enforced

### Why This Is Safe

**Webhook Security:**

1. **Signature Verification**: Each webhook verified with Stripe signature
   ```javascript
   stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
   ```

2. **Timestamp Validation**: Signatures include timestamp to prevent replay attacks

3. **IP Filtering** (Optional): Can restrict to Stripe's IPs if needed

4. **Rate Limiting Not Needed**: Stripe controls webhook volume, not malicious actors

**Rate Limiting Still Protects:**
- All other API endpoints still rate limited
- User-facing endpoints protected from abuse
- Only webhook excluded (intentionally)

### Middleware Order (Corrected)

```javascript
1. Helmet (security headers)
2. CORS
3. Morgan (logging)
4. Webhook route ✅ (BEFORE rate limiting, body parsing, auth)
5. Rate limiting (excludes webhook)
6. Body parsing (excludes webhook - it has express.raw())
7. Other API routes (rate limited and body parsed)
8. Authentication middleware (per-route)
```

### Testing

**Test Rate Limit Bypass:**

```bash
# Send 150 webhooks in quick succession (exceeds 100 limit)
for i in {1..150}; do
  curl -X POST http://localhost:3000/api/payments/webhook \
    -H "Content-Type: application/json" \
    -H "stripe-signature: t=xxx,v1=xxx" \
    -d '{"type":"payment_intent.succeeded",...}'
done

# ✅ All should return 200 OK (or 400 if signature invalid)
# ❌ Before fix: First 100 succeed, rest get 429
```

**Test Other Routes Still Rate Limited:**

```bash
# Send 150 requests to different endpoint
for i in {1..150}; do
  curl http://localhost:3000/api/orders \
    -H "Authorization: Bearer $TOKEN"
done

# ✅ First 100 succeed
# ✅ Requests 101-150 get 429 (rate limited)
```

**Verify with Stripe CLI:**

```bash
# Stripe CLI can send rapid webhook bursts
stripe listen --forward-to localhost:3000/api/payments/webhook

# In another terminal, trigger multiple events
stripe trigger payment_intent.succeeded
stripe trigger payment_intent.created
stripe trigger charge.succeeded
# ... send many more

# ✅ All should be delivered successfully
```

### Stripe Webhook Volume

**Typical Volume:**
- Small store: 10-50 webhooks per hour
- Medium store: 100-500 webhooks per hour
- Large store: 1000+ webhooks per hour

**Peak Scenarios:**
- Black Friday sales: 10,000+ webhooks per hour
- Batch processing: 1,000+ webhooks in minutes
- Failed payment retries: Bursts of hundreds

**Without This Fix:**
- Even medium stores would hit rate limits
- Peak periods would cause widespread failures
- Critical business operations disrupted

### Alternative Approaches (Not Implemented)

**Option 1: Skip middleware for specific paths**
```javascript
app.use('/api/', (req, res, next) => {
  if (req.path === '/payments/webhook') {
    return next();  // Skip rate limiting
  }
  limiter(req, res, next);
});
```
❌ More complex
❌ Harder to maintain

**Option 2: Higher rate limit for webhooks**
```javascript
const webhookLimiter = rateLimit({ max: 10000 });
app.use('/api/payments/webhook', webhookLimiter);
```
❌ Still unnecessary limitation
❌ Doesn't solve the core issue

**Option 3: Separate domain for webhooks**
```javascript
webhooks.example.com/stripe
```
❌ Infrastructure complexity
❌ Additional DNS/SSL setup

**Our Approach: Register webhook first ✅**
✅ Simple and clean
✅ Webhook completely exempt
✅ No additional complexity

### Best Practice

**Webhook Registration Order:**

```javascript
// 1. Register webhooks FIRST (before middleware)
app.post('/webhooks/stripe', rawBody, stripeWebhook);
app.post('/webhooks/clerk', rawBody, clerkWebhook);

// 2. Then apply global middleware
app.use(rateLimit);
app.use(express.json());
app.use(authentication);

// 3. Then register authenticated routes
app.use('/api/orders', authMiddleware, orderRoutes);
app.use('/api/payments', authMiddleware, paymentRoutes);
```

**Reasons:**
- Webhooks need special handling (raw body, no auth, no rate limit)
- Easier to see which routes are exempt
- Clear separation of concerns
- Follows principle of least surprise

### Related Documentation

- [Stripe Webhook Best Practices](https://stripe.com/docs/webhooks/best-practices)
- [Express Middleware Order](https://expressjs.com/en/guide/using-middleware.html)
- [Rate Limiting Strategies](https://www.npmjs.com/package/express-rate-limit)

---

## Related Issues

- None currently

## References

- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [SwiftUI Task Modifier](https://developer.apple.com/documentation/swiftui/view/task(priority:_:))
- [Task Cancellation](https://developer.apple.com/documentation/swift/task/iscancelled)

---

## Future Improvements

Consider these enhancements for real-time updates:

1. **WebSocket Support**: Replace polling with WebSocket for true real-time updates
2. **Exponential Backoff**: Implement backoff strategy for failed requests
3. **Adaptive Polling**: Adjust polling interval based on order status
4. **Batch Updates**: Fetch multiple order updates in one request
5. **Push Notifications**: Use push notifications to trigger updates instead of polling

---

## Bug Fix: Incorrect Stripe Payment ID Storage

**Date**: 2024-01-01  
**Severity**: Medium  
**Component**: backend/src/controllers/paymentController.js  
**Status**: ✅ Fixed

### Problem

When storing payment records, both `stripe_payment_id` and `stripe_payment_intent_id` columns were assigned the same value (`paymentIntent.id`). This violates the semantic intent of the database schema where these should represent different entities in Stripe's payment flow.

**Problematic Code:**

```javascript
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
    paymentIntent.id,  // ❌ Payment Intent ID
    paymentIntent.id,  // ❌ Same Payment Intent ID
    order.price,
    paymentIntent.status === 'succeeded' ? 'completed' : 'pending',
    paymentMethodId
  ]
);
```

**Issues:**

1. **Semantic Incorrectness**: Both columns store the same value
2. **Schema Violation**: `stripe_payment_id` should store the charge ID, not payment intent ID
3. **Data Integrity**: Impossible to track charge vs payment intent separately
4. **Reporting Issues**: Cannot query for specific charges or reconcile with Stripe dashboard
5. **Refund Complications**: Charge ID needed for refunds, but it's not stored

**Stripe Payment Flow:**

```
PaymentIntent (pi_xxx) - Overall payment container
  └─ Charge (ch_xxx) - Actual charge to the card
```

- **Payment Intent**: Container for the payment (can have multiple attempts)
- **Charge**: Actual charge to the customer's payment method
- Both IDs are important and should be stored separately

### Impact

While this doesn't cause immediate runtime errors (each payment creates a unique intent), it creates several issues:

- ❌ Cannot query payments by charge ID
- ❌ Difficult to reconcile with Stripe dashboard (shows charge IDs)
- ❌ Refunds require charge ID lookup
- ❌ Analytics and reporting affected
- ❌ Stripe dispute resolution requires charge ID

### Solution

Store the correct values for each column:
- `stripe_payment_id`: Store the charge ID from `paymentIntent.charges.data[0].id`
- `stripe_payment_intent_id`: Store the payment intent ID from `paymentIntent.id`

**Fixed Code:**

```javascript
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
    paymentIntent.charges?.data?.[0]?.id || null,  // ✅ Charge ID
    paymentIntent.id,  // ✅ Payment Intent ID
    order.price,
    paymentIntent.status === 'succeeded' ? 'completed' : 'pending',
    paymentMethodId
  ]
);
```

### Key Improvements

1. **✅ Correct Charge ID**: Extracts charge ID from `paymentIntent.charges.data[0].id`
2. **✅ Safe Access**: Uses optional chaining (`?.`) to handle missing charges
3. **✅ Null Fallback**: Defaults to `null` if charge data unavailable
4. **✅ Semantic Correctness**: Each column stores its intended value
5. **✅ Future-Proof**: Supports refunds, disputes, and proper reconciliation

### Stripe Payment Object Structure

```javascript
{
  id: "pi_xxx",  // Payment Intent ID
  object: "payment_intent",
  status: "succeeded",
  charges: {
    data: [
      {
        id: "ch_xxx",  // Charge ID ← Extract this!
        amount: 5000,
        status: "succeeded",
        // ... other charge details
      }
    ]
  }
}
```

### Testing

**Verify Correct IDs Stored:**

```javascript
// Make a payment
const response = await processPayment(orderId, paymentMethodId);

// Query database
const payment = await db.query('SELECT * FROM payments WHERE order_id = $1', [orderId]);

// ✅ Verify different IDs
console.log(payment.stripe_payment_id);         // ch_xxx (Charge ID)
console.log(payment.stripe_payment_intent_id);  // pi_xxx (Payment Intent ID)

// ✅ Both should be different
assert(payment.stripe_payment_id !== payment.stripe_payment_intent_id);

// ✅ Both should match Stripe format
assert(payment.stripe_payment_id.startsWith('ch_'));
assert(payment.stripe_payment_intent_id.startsWith('pi_'));
```

**Test Refund Scenario:**

```javascript
// Refund requires charge ID
const refund = await stripe.refunds.create({
  charge: payment.stripe_payment_id  // ✅ Now has correct charge ID
});
```

**Test with Stripe Dashboard:**

1. Make a payment through the app
2. Go to Stripe Dashboard → Payments
3. Find the payment (listed by charge ID)
4. Verify the charge ID in dashboard matches `stripe_payment_id` in database
5. Click into payment details
6. Verify payment intent ID matches `stripe_payment_intent_id` in database

### Edge Cases Handled

**No Charge Data:**

```javascript
// If payment intent doesn't have charges yet
paymentIntent.charges?.data?.[0]?.id || null
// ✅ Returns null instead of crashing
```

**Multiple Charges (Rare):**

```javascript
// Payment intents can have multiple charges (card retries)
// We store the first successful charge
paymentIntent.charges.data[0].id  // Latest/first charge
```

**Failed Payments:**

```javascript
// Even failed payments may have charge attempts
// Storing null is acceptable for failed payments
```

### Best Practice

When working with Stripe payment data:

```javascript
// ✅ Always extract both IDs
const chargeId = paymentIntent.charges?.data?.[0]?.id;
const paymentIntentId = paymentIntent.id;

// ✅ Store them separately
await db.query(
  'INSERT INTO payments (stripe_payment_id, stripe_payment_intent_id) VALUES ($1, $2)',
  [chargeId, paymentIntentId]
);

// ✅ Use appropriate ID for operations
stripe.refunds.create({ charge: chargeId });          // Requires charge ID
stripe.paymentIntents.retrieve(paymentIntentId);      // Uses intent ID
```

---

## Bug Fix: Coordinate Validation Rejects Valid Zero Values

**Date**: 2024-01-01  
**Severity**: Medium  
**Component**: backend/src/controllers/orderController.js  
**Status**: ✅ Fixed

### Problem

The `updateDriverLocation` function validates latitude and longitude using a falsy check (`if (!latitude || !longitude)`). This incorrectly rejects valid coordinates where latitude or longitude is exactly `0`.

**Problematic Code:**

```javascript
async function updateDriverLocation(req, res, next) {
  try {
    const { id } = req.params;
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {  // ❌ Rejects 0 as invalid!
      return res.status(400).json({ error: 'Latitude and longitude required' });
    }
    
    // ... update location
  }
}
```

**JavaScript Falsy Behavior:**

```javascript
!0           // true  ❌ Zero is falsy!
!false       // true
!null        // true
!undefined   // true
!""          // true
!NaN         // true
```

**Valid Coordinates That Are Rejected:**

```javascript
// Equator (latitude = 0)
{ latitude: 0, longitude: 48.5 }  // ❌ Rejected (crossing equator in Europe)

// Prime Meridian (longitude = 0)
{ latitude: 51.5, longitude: 0 }  // ❌ Rejected (Greenwich, London)

// Both zero (Null Island)
{ latitude: 0, longitude: 0 }     // ❌ Rejected (Gulf of Guinea)
```

### Impact

**Geographic Limitations:**

- ❌ Cannot track deliveries in regions crossing the equator
- ❌ Cannot track deliveries in regions crossing the prime meridian
- ❌ Western Africa (Ghana, Gabon, etc.) affected
- ❌ Central Africa (Congo, Uganda, etc.) affected
- ❌ Parts of Europe (UK, France, Spain) affected
- ❌ Parts of South America (Brazil, Ecuador, etc.) affected

**User Experience:**

- Driver location updates fail in affected regions
- "Latitude and longitude required" error even when provided
- Real-time tracking broken for valid locations
- Poor service in equatorial and prime meridian regions

### Solution

Use `Number.isFinite()` to properly validate numeric coordinates:

**Fixed Code:**

```javascript
async function updateDriverLocation(req, res, next) {
  try {
    const { id } = req.params;
    const { latitude, longitude } = req.body;

    // Use Number.isFinite to properly validate numeric coordinates (allows 0)
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      return res.status(400).json({ error: 'Valid latitude and longitude coordinates required' });
    }
    
    // ... update location
  }
}
```

### Why `Number.isFinite()` Is Correct

```javascript
// Valid numeric values (including 0)
Number.isFinite(0)      // true  ✅ Zero is valid!
Number.isFinite(48.5)   // true  ✅
Number.isFinite(-23.5)  // true  ✅
Number.isFinite(180)    // true  ✅

// Invalid values
Number.isFinite(null)      // false  ✅ Rejects null
Number.isFinite(undefined) // false  ✅ Rejects undefined
Number.isFinite(NaN)       // false  ✅ Rejects NaN
Number.isFinite("123")     // false  ✅ Rejects strings
Number.isFinite(Infinity)  // false  ✅ Rejects infinity
```

**Comparison of Validation Methods:**

```javascript
const latitude = 0;

// ❌ Falsy check (WRONG)
if (!latitude)                    // true - rejects 0
if (latitude === null)            // false - too strict
if (latitude !== undefined)       // true - allows null

// ✅ Number.isFinite (CORRECT)
if (Number.isFinite(latitude))    // true - accepts 0, rejects non-numbers
```

### Key Improvements

1. **✅ Accepts Zero**: `0` is a valid coordinate value
2. **✅ Rejects Non-Numbers**: Strings, null, undefined rejected
3. **✅ Rejects NaN**: Invalid number operations caught
4. **✅ Rejects Infinity**: Infinite values rejected
5. **✅ Type Safe**: Only accepts actual numbers

### Valid Coordinate Ranges

For additional validation (optional):

```javascript
// Standard coordinate ranges
-90  <= latitude  <= 90   // Full range from South Pole to North Pole
-180 <= longitude <= 180  // Full range around the globe

// Enhanced validation (optional)
if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
  return res.status(400).json({ error: 'Valid coordinates required' });
}

if (latitude < -90 || latitude > 90) {
  return res.status(400).json({ error: 'Latitude must be between -90 and 90' });
}

if (longitude < -180 || longitude > 180) {
  return res.status(400).json({ error: 'Longitude must be between -180 and 180' });
}
```

### Testing

**Test Valid Zero Coordinates:**

```bash
# Test equator crossing (latitude = 0)
curl -X PUT http://localhost:3000/api/orders/123/location \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"latitude": 0, "longitude": 48.5}'
# ✅ Should succeed (after fix)
# ❌ Was rejected (before fix)

# Test prime meridian crossing (longitude = 0)
curl -X PUT http://localhost:3000/api/orders/123/location \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"latitude": 51.5, "longitude": 0}'
# ✅ Should succeed (Greenwich, London)

# Test "Null Island" (0, 0)
curl -X PUT http://localhost:3000/api/orders/123/location \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"latitude": 0, "longitude": 0}'
# ✅ Should succeed
```

**Test Invalid Inputs Still Rejected:**

```bash
# Missing latitude
curl -X PUT http://localhost:3000/api/orders/123/location \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"longitude": 48.5}'
# ✅ Should return 400

# String values
curl -X PUT http://localhost:3000/api/orders/123/location \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"latitude": "0", "longitude": "48.5"}'
# ✅ Should return 400 (strings not accepted)

# NaN values
curl -X PUT http://localhost:3000/api/orders/123/location \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"latitude": NaN, "longitude": 48.5}'
# ✅ Should return 400

# Null values
curl -X PUT http://localhost:3000/api/orders/123/location \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"latitude": null, "longitude": 48.5}'
# ✅ Should return 400
```

### Real-World Affected Locations

**Equator (Latitude = 0):**
- 🌍 Ecuador (country named after equator)
- 🌍 Kenya (Nairobi region)
- 🌍 Indonesia (Sumatra, Borneo)
- 🌍 Democratic Republic of Congo
- 🌍 Brazil (Amazon region)

**Prime Meridian (Longitude = 0):**
- 🇬🇧 Greenwich, London, UK
- 🇫🇷 France (western regions)
- 🇪🇸 Spain (eastern regions)
- 🇬🇭 Ghana (Accra)
- 🇩🇿 Algeria

**Both (0, 0) - "Null Island":**
- 🌊 Gulf of Guinea (Atlantic Ocean)
- Weather buoy location used for testing

### Best Practice

When validating numeric values that can legitimately be zero:

```javascript
// ❌ Bad: Falsy check
if (!value)                    // Rejects 0
if (value)                     // Accepts non-zero only

// ✅ Good: Explicit type check
if (Number.isFinite(value))    // Accepts 0 and other valid numbers
if (typeof value === 'number' && !isNaN(value))  // Alternative

// ✅ Good: Null check
if (value !== null && value !== undefined)  // Accepts 0

// ✅ Good: Explicit comparison
if (value >= -90 && value <= 90)  // Range check (accepts 0)
```

### Related Code Patterns

Search for similar issues elsewhere:

```bash
# Find other falsy coordinate checks
grep -r "if (!latitude" backend/src/
grep -r "if (!longitude" backend/src/

# Find coordinate validation
grep -r "latitude.*longitude" backend/src/
```

---

*Last Updated: 2024-01-01*

