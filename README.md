# Happy Launderer - iOS Laundry Delivery App

A full-stack iOS application for laundry pickup and delivery services with real-time tracking.

## Tech Stack

### Frontend
- **iOS App**: Swift with SwiftUI
- **Maps**: Apple MapKit
- **Authentication**: Clerk SDK for iOS
- **Payments**: Clerk + Stripe integration

### Backend
- **API**: Node.js with Express
- **Database**: PostgreSQL
- **Hosting**: Railway
- **Push Notifications**: Apple Push Notification service (APNs)

## Project Structure

```
Happy Launderer/
├── ios-app/              # iOS Swift/SwiftUI application
│   ├── HappyLaunderer/   # Main app code
│   ├── Models/           # Data models
│   ├── Views/            # SwiftUI views
│   ├── ViewModels/       # View models (MVVM)
│   ├── Services/         # API clients and services
│   └── Utils/            # Utilities and helpers
├── backend/              # Node.js/Express backend
│   ├── src/
│   │   ├── routes/       # API route handlers
│   │   ├── controllers/  # Business logic
│   │   ├── models/       # Database models
│   │   ├── middleware/   # Express middleware
│   │   └── utils/        # Utility functions
│   └── migrations/       # Database migrations
└── docs/                 # Documentation
```

## Features

### Phase 1: Authentication & Onboarding
- ✓ Clerk-powered authentication (email/password)
- ✓ User profile management
- ✓ Address management

### Phase 2: Booking Interface
- ✓ Pickup/delivery address selection
- ✓ Date/time scheduling
- ✓ Service type selection (standard, express, premium)
- ✓ Real-time price calculation

### Phase 3: Order Tracking
- ✓ Order history and active orders
- ✓ Real-time order status updates
- ✓ Driver location tracking with MapKit
- ✓ Estimated delivery times

### Phase 4: Payments
- ✓ Clerk payment method management
- ✓ Stripe payment processing
- ✓ Payment history

### Phase 5: Notifications & Polish
- ✓ Push notifications for order updates
- ✓ User preferences and settings
- ✓ Order search and filtering

## Getting Started

### Prerequisites
- Xcode 15.0+
- Node.js 18+
- PostgreSQL 14+
- Clerk account with API keys
- Stripe account with API keys
- Apple Developer account (for push notifications)

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```bash
cp .env.example .env
```

4. Configure environment variables in `.env`:
```
DATABASE_URL=postgresql://user:password@host:port/database
CLERK_SECRET_KEY=your_clerk_secret_key
STRIPE_SECRET_KEY=your_stripe_secret_key
PORT=3000
```

5. Run database migrations:
```bash
npm run migrate
```

6. Start the development server:
```bash
npm run dev
```

### iOS App Setup

1. Open Xcode project:
```bash
cd ios-app
open HappyLaunderer.xcodeproj
```

2. Install dependencies via Swift Package Manager:
   - Clerk SDK for iOS
   - (Dependencies auto-install when opening project)

3. Configure `Config.swift` with your API keys:
   - Clerk Publishable Key
   - Backend API URL

4. Build and run the app in Xcode (⌘+R)

## Database Schema

### users
- `id`: UUID (Primary Key)
- `clerk_id`: String (Unique, indexed)
- `name`: String
- `phone`: String
- `default_address`: JSON
- `saved_addresses`: JSON Array
- `created_at`: Timestamp

### orders
- `id`: UUID (Primary Key)
- `user_id`: UUID (Foreign Key → users)
- `pickup_address`: JSON
- `delivery_address`: JSON
- `scheduled_time`: Timestamp
- `status`: Enum (pending, picked_up, in_laundry, ready, out_for_delivery, completed)
- `item_count`: Integer
- `price`: Decimal
- `driver_id`: UUID (nullable)
- `created_at`: Timestamp
- `updated_at`: Timestamp

### payments
- `id`: UUID (Primary Key)
- `order_id`: UUID (Foreign Key → orders)
- `user_id`: UUID (Foreign Key → users)
- `stripe_payment_id`: String
- `amount`: Decimal
- `status`: Enum (pending, completed, failed)
- `created_at`: Timestamp

## API Endpoints

### Authentication
- `POST /auth/profile` - Save/update user profile

### Orders
- `POST /orders` - Create new order
- `GET /orders` - Get user's orders
- `GET /orders/:id` - Get order details
- `PUT /orders/:id` - Update order status (admin/driver)

### Payments
- `POST /payments/charge` - Process payment via Stripe

### Pricing
- `GET /pricing` - Calculate price for service type

## Deployment

### Backend (Railway)
1. Connect your GitHub repository to Railway
2. Configure environment variables in Railway dashboard
3. Deploy automatically on push to main branch

### iOS App (App Store)
1. Archive the app in Xcode
2. Upload to App Store Connect
3. Submit for review

## Environment Variables

### Backend
```
DATABASE_URL=postgresql://...
CLERK_SECRET_KEY=sk_...
STRIPE_SECRET_KEY=sk_...
PORT=3000
NODE_ENV=production
```

### iOS App (Config.swift)
```swift
static let clerkPublishableKey = "pk_..."
static let backendAPIURL = "https://your-api.railway.app"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details

## Support

For issues or questions, please open an issue on GitHub.

