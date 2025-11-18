# Happy Launderer - Architecture Documentation

## System Architecture

### Overview

Happy Launderer is a full-stack mobile application built with a native iOS frontend and a Node.js backend, following a client-server architecture with third-party integrations for authentication, payments, and notifications.

```
┌─────────────────────────────────────────────────────────────┐
│                         iOS App                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              SwiftUI Views                            │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         ViewModels & Managers (MVVM)                  │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Services & API Client                    │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │ HTTPS
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   Backend API (Node.js)                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          Express Routes & Middleware                  │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Controllers & Business Logic             │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  Database Layer                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
      PostgreSQL        Clerk API      Stripe API
```

---

## Frontend Architecture (iOS)

### Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture Pattern**: MVVM (Model-View-ViewModel)
- **Networking**: URLSession with async/await
- **State Management**: ObservableObject + @Published
- **Authentication**: Clerk iOS SDK
- **Maps**: Apple MapKit
- **Minimum iOS Version**: iOS 16.0+

### Project Structure

```
ios-app/HappyLaunderer/
├── HappyLaundererApp.swift         # App entry point
├── ContentView.swift                # Main content view
├── Config.swift                     # Configuration & API keys
├── Models/                          # Data models
│   ├── User.swift
│   ├── Order.swift
│   └── Payment.swift
├── Services/                        # Business logic & API
│   ├── APIClient.swift              # Base HTTP client
│   ├── AuthenticationManager.swift  # Auth state & operations
│   ├── OrderManager.swift           # Order management
│   ├── PaymentManager.swift         # Payment processing
│   └── NotificationManager.swift    # Push notifications
├── Views/                           # UI components
│   ├── Authentication/              # Login, signup, profile setup
│   ├── Home/                        # Home screen
│   ├── Orders/                      # Order creation & tracking
│   └── Profile/                     # User profile & settings
└── Utils/                           # Utility functions & extensions
```

### Design Patterns

#### MVVM (Model-View-ViewModel)

- **Models**: Plain Swift structs conforming to Codable
- **Views**: SwiftUI views (declarative UI)
- **ViewModels**: Manager classes with `@Published` properties

Example:
```swift
// Model
struct Order: Codable, Identifiable {
    let id: String
    let status: OrderStatus
    // ...
}

// ViewModel
class OrderManager: ObservableObject {
    @Published var orders: [Order] = []
    
    func fetchOrders() async throws {
        // Fetch from API
    }
}

// View
struct OrdersListView: View {
    @EnvironmentObject var orderManager: OrderManager
    
    var body: some View {
        List(orderManager.orders) { order in
            OrderRowView(order: order)
        }
    }
}
```

#### Dependency Injection

Using SwiftUI's `@EnvironmentObject` for dependency injection:

```swift
@main
struct HappyLaundererApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var orderManager = OrderManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(orderManager)
        }
    }
}
```

### State Management

#### Authentication State

Managed by `AuthenticationManager`:
- Session token storage in UserDefaults
- Current user profile caching
- Authentication status (`isAuthenticated`, `isLoading`)

#### Order State

Managed by `OrderManager`:
- Order list caching
- Active orders filtering
- Real-time updates via polling

### Navigation

Using SwiftUI's native navigation:
- `TabView` for main navigation
- `NavigationView` + `NavigationLink` for hierarchical navigation
- `.sheet()` for modal presentations

---

## Backend Architecture (Node.js)

### Technology Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL 14+
- **ORM**: Direct SQL queries with pg
- **Authentication**: Clerk Node SDK
- **Payments**: Stripe Node SDK
- **Validation**: Joi
- **Security**: Helmet, CORS, Rate Limiting

### Project Structure

```
backend/
├── src/
│   ├── index.js                    # App entry point
│   ├── config/
│   │   └── database.js             # Database connection
│   ├── middleware/
│   │   ├── auth.js                 # Authentication middleware
│   │   └── errorHandler.js         # Error handling
│   ├── routes/
│   │   ├── auth.js                 # Auth routes
│   │   ├── orders.js               # Order routes
│   │   ├── payments.js             # Payment routes
│   │   └── pricing.js              # Pricing routes
│   ├── controllers/
│   │   ├── authController.js       # Auth business logic
│   │   ├── orderController.js      # Order business logic
│   │   ├── paymentController.js    # Payment business logic
│   │   └── pricingController.js    # Pricing business logic
│   └── migrations/
│       ├── 001_initial_schema.sql  # Database schema
│       └── run.js                  # Migration runner
├── package.json
└── .env                            # Environment variables
```

### Middleware Chain

```
Request
  │
  ├─> Helmet (Security headers)
  ├─> CORS (Cross-origin requests)
  ├─> Rate Limiter (100 req/15min)
  ├─> Morgan (Logging)
  ├─> Body Parser (JSON)
  ├─> Auth Middleware (Verify Clerk token)
  ├─> Route Handler
  └─> Error Handler
  │
Response
```

### Database Schema

#### Entity Relationship Diagram

```
┌─────────────┐         ┌──────────────┐         ┌──────────────┐
│    Users    │────────<│    Orders    │>────────│   Payments   │
└─────────────┘         └──────────────┘         └──────────────┘
                               │
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Order Status History│
                    └─────────────────────┘
```

#### Tables

**users**
- id (UUID, PK)
- clerk_id (VARCHAR, Unique)
- name, phone
- default_address (JSONB)
- saved_addresses (JSONB Array)
- timestamps

**orders**
- id (UUID, PK)
- user_id (UUID, FK → users)
- pickup_address, delivery_address (JSONB)
- scheduled_time (TIMESTAMP)
- status (ENUM)
- service_type (ENUM)
- price (DECIMAL)
- driver_id (UUID)
- driver_location (JSONB)
- timestamps

**payments**
- id (UUID, PK)
- order_id (UUID, FK → orders)
- user_id (UUID, FK → users)
- stripe_payment_id (VARCHAR)
- amount (DECIMAL)
- status (ENUM)
- timestamps

**order_status_history**
- id (UUID, PK)
- order_id (UUID, FK → orders)
- old_status, new_status (ENUM)
- changed_by (UUID)
- notes (TEXT)
- created_at (TIMESTAMP)

### API Architecture

#### RESTful Design

Following REST principles:
- Resources: `/users`, `/orders`, `/payments`
- HTTP methods: GET, POST, PUT, DELETE
- Stateless: Each request contains all necessary information
- JSON responses

#### Error Handling

Centralized error handling:
```javascript
// Controllers throw errors
if (!order) {
  throw new Error('Order not found');
}

// Error handler middleware catches and formats
app.use(errorHandler);
```

#### Validation

Input validation using Joi:
```javascript
const schema = Joi.object({
  scheduledTime: Joi.date().iso().required(),
  serviceType: Joi.string().valid('standard', 'express', 'premium').required()
});

const { error, value } = schema.validate(req.body);
```

---

## Third-Party Integrations

### Clerk (Authentication)

**Purpose**: User authentication and session management

**Integration Points**:
- iOS app: Direct Clerk SDK integration
- Backend: Token verification via Clerk API

**Flow**:
```
1. User signs up/logs in via Clerk in iOS app
2. Clerk returns session token
3. iOS app sends token with each API request
4. Backend verifies token with Clerk API
5. Backend grants access to protected resources
```

### Stripe (Payments)

**Purpose**: Payment processing

**Integration Points**:
- Backend: Create payment intents, process charges
- iOS app: Display payment UI (future: Stripe iOS SDK)

**Flow**:
```
1. User creates order in iOS app
2. iOS app requests payment from backend
3. Backend creates Stripe PaymentIntent
4. Backend charges payment method via Stripe
5. Stripe webhook notifies backend of success/failure
6. Backend updates payment status
```

### Apple Push Notification Service (APNs)

**Purpose**: Push notifications for order updates

**Integration Points**:
- iOS app: Register for notifications, handle incoming
- Backend: Send notifications via APNs

**Flow**:
```
1. iOS app requests notification permission
2. APNs provides device token
3. iOS app sends token to backend
4. Backend stores token associated with user
5. On order status change, backend sends notification via APNs
6. iOS app receives and displays notification
```

### Apple MapKit

**Purpose**: Display driver location and addresses

**Integration Points**:
- iOS app only (native Apple framework)

**Features**:
- Display map with driver location
- Show pickup/delivery addresses
- Real-time location updates

---

## Data Flow Examples

### Order Creation Flow

```
1. User fills out order form in iOS app
   ├─> NewOrderView captures input
   └─> Validates addresses and time

2. User taps "Create Order"
   ├─> OrderManager.createOrder() called
   └─> API request sent to backend

3. Backend receives request
   ├─> Auth middleware verifies token
   ├─> orderController.createOrder()
   ├─> Calculate price
   ├─> Insert into database
   └─> Return order object

4. iOS app receives response
   ├─> OrderManager updates state
   ├─> Navigate to order detail
   └─> Show success message
```

### Real-Time Order Tracking

```
1. User opens OrderDetailView
   ├─> Fetch order details
   └─> Start polling for updates

2. Every 30 seconds
   ├─> OrderManager.fetchOrderDetails()
   ├─> GET /api/orders/:id
   └─> Update UI with latest status

3. If driver location available
   ├─> Display map
   ├─> Show driver marker
   └─> Update region center

4. If status changes
   ├─> Update status indicator
   ├─> Add to status history
   └─> (Optional) Show notification
```

---

## Security Architecture

### Authentication & Authorization

**JWT-based authentication**:
- Clerk issues JWT tokens
- Backend verifies signature
- Token contains user ID and metadata

**Role-based access control**:
- User: Can create orders, view own orders
- Driver: Can update order status, location
- Admin: Full access

### Data Protection

**In Transit**:
- HTTPS for all API communication
- TLS 1.2+ required

**At Rest**:
- Database encryption via PostgreSQL
- Sensitive data (payment info) stored in Stripe

**In App**:
- Token stored in UserDefaults (sandboxed)
- No plaintext passwords

### API Security

**Rate Limiting**: 100 requests per 15 minutes per IP
**Input Validation**: All inputs validated with Joi
**SQL Injection Prevention**: Parameterized queries
**XSS Prevention**: No HTML rendering of user input
**CSRF Prevention**: Token-based authentication (no cookies)

---

## Scalability Considerations

### Backend Scaling

**Horizontal Scaling**:
- Stateless API design allows multiple instances
- Load balancer distributes traffic
- Session state managed by Clerk (external)

**Database Scaling**:
- Connection pooling (pg Pool)
- Read replicas for read-heavy operations
- Indexing on frequently queried fields

**Caching** (Future):
- Redis for session caching
- Cache frequent queries (pricing, user profiles)

### iOS App Performance

**Efficient Networking**:
- Request deduplication
- Caching responses
- Pagination for large lists

**Memory Management**:
- SwiftUI automatic memory management
- Image lazy loading
- Dispose of observers

**Background Tasks**:
- Efficient location updates
- Background notification handling

---

## Monitoring & Logging

### Backend Logging

**Morgan HTTP Logger**:
- All incoming requests logged
- Response times tracked

**Error Logging**:
- All errors logged to console
- Include stack traces for debugging

**Future Enhancements**:
- Centralized logging (e.g., Datadog, LogRocket)
- Performance monitoring (e.g., New Relic)
- Error tracking (e.g., Sentry)

### iOS App Logging

**Console Logging**:
- Network errors
- Authentication failures
- State changes

**Future Enhancements**:
- Crash reporting (e.g., Firebase Crashlytics)
- Analytics (e.g., Mixpanel, Amplitude)
- Performance monitoring (e.g., Firebase Performance)

---

## Testing Strategy

### Backend Testing

**Unit Tests**:
- Controller logic
- Input validation
- Error handling

**Integration Tests**:
- API endpoints
- Database operations
- Third-party integrations

**Manual Testing**:
- Postman collection for API testing

### iOS App Testing

**Unit Tests**:
- Model logic
- Manager methods
- Utility functions

**UI Tests**:
- Critical user flows
- Form validation
- Navigation

**Manual Testing**:
- Simulator testing
- TestFlight beta testing
- Physical device testing

---

## Future Enhancements

### Technical Improvements

1. **WebSocket for Real-Time Updates**
   - Replace polling with WebSocket connection
   - Instant order status updates

2. **GraphQL API**
   - More efficient data fetching
   - Reduce over-fetching

3. **Offline Support**
   - Local data caching
   - Sync when online

4. **App Clips**
   - Quick order placement without full app install

5. **Widget Support**
   - Home screen widget for order tracking

### Feature Additions

1. **In-App Chat**
   - Customer support chat
   - Driver communication

2. **Loyalty Program**
   - Points system
   - Rewards tracking

3. **Subscription Plans**
   - Monthly laundry subscriptions
   - Discounted pricing

4. **Multi-Language Support**
   - Localization
   - RTL language support

---

## Conclusion

The Happy Launderer architecture is designed for:
- **Maintainability**: Clean separation of concerns
- **Scalability**: Horizontal scaling capability
- **Security**: Industry-standard practices
- **Performance**: Efficient data flow and caching
- **Extensibility**: Easy to add new features

The system is production-ready and follows best practices for modern mobile and web applications.

