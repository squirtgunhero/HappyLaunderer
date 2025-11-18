# Happy Launderer - Complete Setup Guide

This guide will walk you through setting up the Happy Launderer iOS app and backend from scratch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Setup](#backend-setup)
3. [Database Setup](#database-setup)
4. [iOS App Setup](#ios-app-setup)
5. [Clerk Configuration](#clerk-configuration)
6. [Stripe Configuration](#stripe-configuration)
7. [Push Notifications Setup](#push-notifications-setup)
8. [Deployment](#deployment)

---

## Prerequisites

### Required Software

- **Node.js**: Version 18+ ([Download](https://nodejs.org/))
- **PostgreSQL**: Version 14+ ([Download](https://www.postgresql.org/download/))
- **Xcode**: Version 15.0+ (From Mac App Store)
- **Git**: For version control

### Required Accounts

1. **Clerk Account**: [Sign up at clerk.com](https://clerk.com/)
2. **Stripe Account**: [Sign up at stripe.com](https://stripe.com/)
3. **Apple Developer Account**: For push notifications and App Store deployment ($99/year)
4. **Railway Account**: For backend hosting ([Sign up at railway.app](https://railway.app/))

---

## Backend Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Environment Configuration

Create a `.env` file in the `backend` directory:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/happy_launderer

# Clerk Authentication
CLERK_SECRET_KEY=sk_test_your_clerk_secret_key

# Stripe Payments
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# Server
PORT=3000
NODE_ENV=development

# CORS
ALLOWED_ORIGINS=http://localhost:3000,capacitor://localhost
```

### 3. Database Migration

Run the database migration to create tables:

```bash
npm run migrate
```

### 4. Start Development Server

```bash
npm run dev
```

The API should now be running at `http://localhost:3000`

### 5. Verify Installation

Test the health endpoint:

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

---

## Database Setup

### Local PostgreSQL Setup

#### macOS (using Homebrew)

```bash
# Install PostgreSQL
brew install postgresql@14

# Start PostgreSQL service
brew services start postgresql@14

# Create database
createdb happy_launderer

# Create user (optional)
psql postgres
CREATE USER laundry_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE happy_launderer TO laundry_user;
\q
```

#### Windows

1. Download PostgreSQL installer from [postgresql.org](https://www.postgresql.org/download/windows/)
2. Run installer and follow wizard
3. Open pgAdmin 4
4. Create new database named `happy_launderer`

### Railway PostgreSQL Setup (Production)

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Create new project
3. Add PostgreSQL database
4. Copy the `DATABASE_URL` from Railway
5. Update your `.env` file with production `DATABASE_URL`

---

## iOS App Setup

### 1. Open Project in Xcode

```bash
cd ios-app
open HappyLaunderer.xcodeproj
```

If you don't have an Xcode project file yet, create one:
1. Open Xcode
2. File → New → Project
3. Select "iOS" → "App"
4. Product Name: "HappyLaunderer"
5. Interface: SwiftUI
6. Language: Swift

### 2. Configure Bundle Identifier

1. Select project in Xcode navigator
2. Select "HappyLaunderer" target
3. General tab
4. Update Bundle Identifier: `com.yourcompany.happylaunderer`

### 3. Add Required Capabilities

1. Select project → Signing & Capabilities
2. Click "+ Capability"
3. Add:
   - Push Notifications
   - Background Modes (check "Location updates" and "Remote notifications")
   - Maps

### 4. Configure API Keys

Edit `Config.swift`:

```swift
struct Config {
    static let backendAPIURL = "http://localhost:3000/api" // or your Railway URL
    static let clerkPublishableKey = "pk_test_your_clerk_publishable_key"
    static let stripePublishableKey = "pk_test_your_stripe_publishable_key"
}
```

### 5. Install Dependencies via Swift Package Manager

1. File → Add Packages
2. Add the following packages:
   - Clerk iOS SDK: `https://github.com/clerk/clerk-ios`
   - (Optional) Any other dependencies

### 6. Build and Run

1. Select a simulator or connected device
2. Press ⌘+R to build and run
3. The app should launch in the simulator

---

## Clerk Configuration

### 1. Create Clerk Application

1. Log in to [Clerk Dashboard](https://dashboard.clerk.com/)
2. Create new application
3. Choose authentication methods (Email/Password, OAuth, etc.)

### 2. Get API Keys

1. Go to API Keys section
2. Copy:
   - **Publishable Key** (starts with `pk_test_`) → iOS `Config.swift`
   - **Secret Key** (starts with `sk_test_`) → Backend `.env`

### 3. Configure Redirect URLs

In Clerk Dashboard:
1. Go to Settings → Paths
2. Add redirect URLs:
   - `happylaunderer://auth-callback`
   - `http://localhost:3000/auth-callback` (for testing)

### 4. Enable Stripe Integration (Optional)

1. Go to Integrations → Stripe
2. Connect your Stripe account
3. This allows Clerk to manage payment methods

### 5. Configure Webhooks

1. Go to Webhooks section
2. Add endpoint: `https://your-api.railway.app/webhooks/clerk`
3. Subscribe to events:
   - `user.created`
   - `user.updated`
   - `session.created`

---

## Stripe Configuration

### 1. Get API Keys

1. Log in to [Stripe Dashboard](https://dashboard.stripe.com/)
2. Go to Developers → API Keys
3. Copy:
   - **Publishable Key** → iOS `Config.swift`
   - **Secret Key** → Backend `.env`

### 2. Set Up Webhooks

1. Go to Developers → Webhooks
2. Add endpoint: `https://your-api.railway.app/api/payments/webhook`
3. Select events:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
4. Copy **Signing Secret** → Backend `.env` as `STRIPE_WEBHOOK_SECRET`

### 3. Test Mode vs Live Mode

- Use **Test Mode** keys (starting with `pk_test_` and `sk_test_`) during development
- Switch to **Live Mode** keys for production
- Test with Stripe test cards: `4242 4242 4242 4242`

### 4. Configure Payment Methods

1. Go to Settings → Payment Methods
2. Enable desired payment methods:
   - Cards
   - Apple Pay
   - Google Pay

---

## Push Notifications Setup

### 1. Create App ID in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Certificates, IDs & Profiles → Identifiers
3. Create new App ID
4. Enable Push Notifications capability

### 2. Generate APNs Certificate

1. In App ID settings, configure Push Notifications
2. Create SSL Certificate
3. Download and install certificate

### 3. Create Authentication Key (Recommended)

1. Keys section → Create new key
2. Enable Apple Push Notifications service (APNs)
3. Download `.p8` file
4. Note the Key ID and Team ID

### 4. Configure in Backend

Add to backend `.env`:

```env
APNS_KEY_ID=your_key_id
APNS_TEAM_ID=your_team_id
APNS_KEY_PATH=/path/to/AuthKey.p8
APNS_TOPIC=com.yourcompany.happylaunderer
```

### 5. Request Permissions in App

The app already includes notification permission requests in `NotificationSettingsView.swift`.

### 6. Test Push Notifications

Use a tool like [Pusher](https://github.com/noodlewerk/NWPusher) or Postman to send test notifications.

---

## Deployment

### Backend Deployment (Railway)

#### 1. Connect GitHub Repository

1. Create GitHub repository
2. Push your code:
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourusername/happy-launderer.git
git push -u origin main
```

#### 2. Deploy to Railway

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. New Project → Deploy from GitHub repo
3. Select your repository
4. Railway will auto-detect Node.js and deploy

#### 3. Configure Environment Variables

1. In Railway project, go to Variables
2. Add all environment variables from `.env`
3. Update `DATABASE_URL` with Railway PostgreSQL URL

#### 4. Run Migrations

1. In Railway project settings
2. Add start command: `npm run migrate && npm start`

#### 5. Get Deployment URL

Railway will provide a URL like: `https://your-app.railway.app`

### iOS App Deployment (App Store)

#### 1. Prepare for Archive

1. Update version number in Xcode
2. Set scheme to "Any iOS Device"
3. Update API URLs in `Config.swift` to production

#### 2. Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. My Apps → + → New App
3. Fill in app information
4. Create app record

#### 3. Archive the App

1. In Xcode: Product → Archive
2. Wait for archive to complete
3. Organizer window will open

#### 4. Upload to App Store

1. Click "Distribute App"
2. Select "App Store Connect"
3. Upload
4. Wait for processing

#### 5. Submit for Review

1. In App Store Connect, complete app information
2. Add screenshots
3. Submit for review

---

## Troubleshooting

### Backend Issues

**Database connection fails:**
```bash
# Check PostgreSQL is running
pg_isready

# Check database exists
psql -l | grep happy_launderer
```

**Port already in use:**
```bash
# Find process using port 3000
lsof -ti:3000

# Kill the process
kill -9 $(lsof -ti:3000)
```

### iOS App Issues

**Build fails:**
1. Clean build folder: ⌘+Shift+K
2. Delete Derived Data: Xcode → Preferences → Locations
3. Restart Xcode

**Clerk authentication not working:**
1. Verify API keys in `Config.swift`
2. Check redirect URLs in Clerk Dashboard
3. Ensure network calls are allowed (Info.plist)

**Push notifications not working:**
1. Verify device is registered
2. Check APNs certificate/key
3. Test in production (push notifications don't work in simulator with production certificates)

---

## Testing

### Backend API Testing

Use the provided Postman collection or curl commands:

```bash
# Create user profile
curl -X POST http://localhost:3000/api/auth/profile \
  -H "Authorization: Bearer your_clerk_token" \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "phone": "555-1234"}'

# Create order
curl -X POST http://localhost:3000/api/orders \
  -H "Authorization: Bearer your_clerk_token" \
  -H "Content-Type: application/json" \
  -d '{
    "pickupAddress": {...},
    "deliveryAddress": {...},
    "scheduledTime": "2024-01-15T10:00:00Z",
    "serviceType": "standard"
  }'
```

### iOS App Testing

1. **Unit Tests**: Run tests with ⌘+U
2. **UI Tests**: Create UI test target and add tests
3. **Manual Testing**: Follow user flows in simulator

---

## Security Best Practices

1. **Never commit `.env` files** - Already in `.gitignore`
2. **Use environment variables** for all secrets
3. **Enable HTTPS** in production
4. **Validate all inputs** on backend
5. **Use prepared statements** for database queries (already implemented)
6. **Rate limit API endpoints** (already implemented with `express-rate-limit`)
7. **Sanitize user inputs**
8. **Keep dependencies updated**: `npm audit fix`

---

## Support

For issues or questions:

1. Check this documentation
2. Review API documentation in `/docs/API.md`
3. Check backend logs: Railway dashboard or local console
4. Check iOS logs: Xcode console

---

## Next Steps

After successful setup:

1. ✅ Test authentication flow
2. ✅ Test order creation
3. ✅ Test payment processing
4. ✅ Test push notifications
5. ✅ Deploy to staging environment
6. ✅ Conduct user testing
7. ✅ Deploy to production
8. ✅ Submit to App Store

Congratulations! Your Happy Launderer app is ready to go! 🎉

