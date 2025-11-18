# Happy Launderer - Quick Start Guide

Get up and running with Happy Launderer in 15 minutes!

## Prerequisites

- Node.js 18+ installed
- PostgreSQL 14+ installed and running
- Xcode 15.0+ installed (macOS only)
- Clerk account ([sign up here](https://clerk.com))
- Stripe account ([sign up here](https://stripe.com))

---

## Backend Setup (5 minutes)

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Configure Environment
```bash
cp .env.example .env
```

Edit `.env` and add your credentials:
```env
DATABASE_URL=postgresql://localhost:5432/happy_launderer
CLERK_SECRET_KEY=sk_test_your_clerk_secret_key
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
PORT=3000
```

### 3. Create Database
```bash
# macOS with Homebrew
createdb happy_launderer

# Or use psql
psql postgres -c "CREATE DATABASE happy_launderer;"
```

### 4. Run Migrations
```bash
npm run migrate
```

### 5. Start Server
```bash
npm run dev
```

Server should be running at `http://localhost:3000`

**Test it:**
```bash
curl http://localhost:3000/health
# Should return: {"status":"ok","timestamp":"..."}
```

---

## iOS App Setup (5 minutes)

### 1. Open Project
```bash
cd ios-app
open HappyLaunderer.xcodeproj
```

### 2. Configure API Keys

Edit `Config.swift`:
```swift
struct Config {
    static let backendAPIURL = "http://localhost:3000/api"
    static let clerkPublishableKey = "pk_test_your_clerk_key"
    static let stripePublishableKey = "pk_test_your_stripe_key"
}
```

### 3. Add Dependencies

In Xcode:
1. File → Add Packages
2. Add Clerk iOS SDK: `https://github.com/clerk/clerk-ios`

### 4. Build and Run

1. Select simulator (iPhone 14 Pro or similar)
2. Press ⌘+R
3. App should launch!

---

## First-Time Usage (5 minutes)

### 1. Create Account

1. Launch the app
2. Tap "Sign Up"
3. Enter your details:
   - Email: `test@example.com`
   - Password: `testpassword123`
   - Name: `Test User`

### 2. Complete Profile

1. Add phone number: `555-123-4567`
2. Add default address:
   - Street: `123 Main St`
   - City: `San Francisco`
   - State: `CA`
   - ZIP: `94102`

### 3. Create First Order

1. Tap "Request Pickup"
2. Select pickup address (use default)
3. Select delivery address (same as pickup)
4. Choose pickup time (tomorrow at 10 AM)
5. Select service type: **Express** ($40)
6. Tap "Create Order"

### 4. View Order

1. Go to "Orders" tab
2. See your new order with status "Pending"
3. Tap to view details

---

## Testing Payments

### Use Stripe Test Cards

**Success:**
- Card: `4242 4242 4242 4242`
- Expiry: Any future date (e.g., `12/25`)
- CVC: Any 3 digits (e.g., `123`)
- ZIP: Any 5 digits (e.g., `12345`)

**Decline:**
- Card: `4000 0000 0000 0002`

---

## Common Issues

### Backend won't start

**Error: `ECONNREFUSED` (Database)**
```bash
# Check if PostgreSQL is running
pg_isready

# Start PostgreSQL (macOS with Homebrew)
brew services start postgresql@14
```

**Error: `Port 3000 already in use`**
```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9
```

### iOS app won't build

**Error: Missing dependencies**
1. File → Packages → Reset Package Caches
2. Clean Build Folder (⌘+Shift+K)
3. Build again (⌘+R)

**Error: Clerk authentication fails**
- Double-check `clerkPublishableKey` in `Config.swift`
- Ensure you're using the correct key (starts with `pk_test_`)

### App can't connect to backend

**From simulator:**
- Use `http://localhost:3000/api` in Config.swift

**From physical device:**
- Use your Mac's IP address: `http://192.168.1.XXX:3000/api`
- Find your IP: System Preferences → Network

---

## Next Steps

Now that you're up and running:

1. ✅ **Read the full setup guide**: `docs/SETUP_GUIDE.md`
2. ✅ **Explore the API**: `docs/API_DOCUMENTATION.md`
3. ✅ **Understand the architecture**: `docs/ARCHITECTURE.md`
4. ✅ **Configure production deployment**: `docs/DEPLOYMENT.md`
5. ✅ **Start customizing** the app for your needs!

---

## Need Help?

- **Documentation**: Check `/docs` folder
- **API Issues**: Review backend logs in terminal
- **iOS Issues**: Check Xcode console for errors
- **Questions**: Open an issue on GitHub

---

## Quick Reference

### Backend Commands
```bash
npm run dev          # Start development server
npm run migrate      # Run database migrations
npm start           # Start production server
npm test            # Run tests (when implemented)
```

### Useful URLs
- Backend API: http://localhost:3000
- Health Check: http://localhost:3000/health
- Clerk Dashboard: https://dashboard.clerk.com
- Stripe Dashboard: https://dashboard.stripe.com

### Test Accounts
```
Email: test@example.com
Password: testpassword123
```

### Service Pricing
- Standard: $25 (3-5 business days)
- Express: $40 (24-48 hours)
- Premium: $60 (Same day)

---

**🎉 Congratulations!** You're now ready to develop with Happy Launderer!

For detailed information, see the complete documentation in the `/docs` folder.

