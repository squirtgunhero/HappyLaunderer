# Happy Launderer - Deployment Guide

Complete guide for deploying the Happy Launderer application to production.

---

## Pre-Deployment Checklist

### Code Preparation

- [ ] All features tested and working
- [ ] Remove all console.log statements (or use proper logging)
- [ ] Update version numbers
- [ ] Remove debug code and comments
- [ ] Run linters and fix issues
- [ ] Update environment variables for production
- [ ] Test with production API keys in staging

### Documentation

- [ ] Update README with production URLs
- [ ] Document any breaking changes
- [ ] Update API documentation
- [ ] Create release notes

### Security

- [ ] Rotate all API keys and secrets
- [ ] Enable HTTPS for all endpoints
- [ ] Configure CORS properly
- [ ] Set up rate limiting
- [ ] Review and update security policies

---

## Backend Deployment (Railway)

### Step 1: Prepare for Deployment

1. **Create Production Branch** (Optional but Recommended)
```bash
git checkout -b production
```

2. **Update Environment Variables**
   - Use production database URL
   - Use production Clerk keys
   - Use production Stripe keys
   - Set `NODE_ENV=production`

3. **Test Build Locally**
```bash
npm install
npm start
```

### Step 2: Deploy to Railway

#### First-Time Setup

1. **Install Railway CLI**
```bash
npm install -g @railway/cli
```

2. **Login to Railway**
```bash
railway login
```

3. **Initialize Project**
```bash
cd backend
railway init
```

4. **Link to Existing Project** (if already created)
```bash
railway link
```

#### Deploy from GitHub

1. **Push Code to GitHub**
```bash
git add .
git commit -m "Prepare for production deployment"
git push origin main
```

2. **Connect Railway to GitHub**
   - Go to Railway Dashboard
   - New Project → Deploy from GitHub repo
   - Select your repository
   - Select branch (main or production)

3. **Configure Build Settings**
   - Root Directory: `backend/`
   - Build Command: `npm install`
   - Start Command: `npm start`

#### Deploy from CLI

```bash
railway up
```

### Step 3: Configure Environment Variables

In Railway Dashboard:

1. Go to your project
2. Click "Variables"
3. Add all environment variables:

```env
DATABASE_URL=<railway_postgres_url>
CLERK_SECRET_KEY=sk_live_xxx
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
PORT=3000
NODE_ENV=production
ALLOWED_ORIGINS=https://your-production-url.com
```

### Step 4: Add PostgreSQL Database

1. In Railway project, click "New"
2. Select "Database" → "PostgreSQL"
3. Copy the `DATABASE_URL`
4. Add to environment variables

### Step 5: Run Migrations

Railway doesn't automatically run migrations. Two options:

**Option 1: Update Start Command**
```bash
npm run migrate && npm start
```

**Option 2: Run Manually via CLI**
```bash
railway run npm run migrate
```

### Step 6: Configure Custom Domain (Optional)

1. In Railway project, go to "Settings"
2. Click "Generate Domain" for a free Railway domain
3. Or add custom domain:
   - Click "Custom Domain"
   - Add your domain
   - Update DNS records as instructed

### Step 7: Set Up Health Checks

Railway automatically monitors your app via the PORT environment variable.

Add a health check endpoint (already implemented):
```javascript
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
```

### Step 8: Configure Webhooks

**Stripe Webhook:**
1. Go to Stripe Dashboard → Webhooks
2. Update endpoint URL: `https://your-railway-app.railway.app/api/payments/webhook`
3. Copy webhook signing secret
4. Update `STRIPE_WEBHOOK_SECRET` in Railway

**Clerk Webhook:**
1. Go to Clerk Dashboard → Webhooks
2. Add endpoint: `https://your-railway-app.railway.app/webhooks/clerk`
3. Select events: user.created, user.updated

### Step 9: Test Deployment

```bash
# Test health endpoint
curl https://your-railway-app.railway.app/health

# Test API endpoint (with auth)
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://your-railway-app.railway.app/api/orders
```

---

## iOS App Deployment (App Store)

### Step 1: Prepare App for Release

1. **Update Version and Build Numbers**
   - In Xcode, select project
   - General tab → Identity
   - Update Version (e.g., 1.0.0)
   - Update Build (e.g., 1)

2. **Update Config with Production URLs**
   
Edit `Config.swift`:
```swift
struct Config {
    static let backendAPIURL = "https://your-railway-app.railway.app/api"
    static let clerkPublishableKey = "pk_live_xxx"
    static let stripePublishableKey = "pk_live_xxx"
}
```

3. **Update App Icons**
   - Add app icons for all required sizes
   - Use Assets.xcassets → AppIcon

4. **Update Launch Screen**
   - Design launch screen in Xcode

5. **Test on Physical Device**
   - Connect iPhone
   - Build and run on device
   - Test all features

### Step 2: Configure App Store Connect

1. **Create App Record**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - My Apps → + → New App
   - Fill in:
     - Platform: iOS
     - Name: Happy Launderer
     - Primary Language: English
     - Bundle ID: com.yourcompany.happylaunderer
     - SKU: unique identifier

2. **Add App Information**
   - Category: Lifestyle
   - Subtitle: Laundry made easy
   - Description: (Write compelling description)
   - Keywords: laundry, delivery, cleaning, wash
   - Support URL: Your website
   - Marketing URL: (Optional)

3. **Prepare Screenshots**

Required sizes:
- 6.5" Display (1284 x 2778 pixels) - iPhone 14 Pro Max
- 5.5" Display (1242 x 2208 pixels) - iPhone 8 Plus

Take screenshots:
- Home screen
- Order creation
- Order tracking
- Profile/settings
- At least 3-5 screenshots

4. **App Preview Video** (Optional but Recommended)
   - 15-30 second demo
   - Show key features

### Step 3: Configure Signing

1. **In Xcode:**
   - Select project → Signing & Capabilities
   - Team: Select your developer account
   - Signing Certificate: "Apple Distribution"
   - Provisioning Profile: "App Store"

2. **If Certificate Missing:**
   - Go to [Apple Developer Portal](https://developer.apple.com)
   - Certificates, IDs & Profiles
   - Create new Distribution Certificate
   - Download and install

### Step 4: Archive the App

1. **Clean Build Folder**
   - Product → Clean Build Folder (⌘+Shift+K)

2. **Select Build Target**
   - At top of Xcode: Select "Any iOS Device (arm64)"

3. **Archive**
   - Product → Archive
   - Wait for archive to complete (can take 5-10 minutes)

4. **Organizer Opens**
   - Shows list of archives
   - Select latest archive

### Step 5: Validate the Archive

1. Click "Validate App"
2. Select distribution method: "App Store Connect"
3. Select options:
   - ✓ Upload your app's symbols
   - ✓ Manage Version and Build Number (recommended)
4. Click "Validate"
5. Wait for validation (3-5 minutes)
6. Fix any errors or warnings

### Step 6: Upload to App Store

1. Click "Distribute App"
2. Select "App Store Connect"
3. Select "Upload"
4. Review summary
5. Click "Upload"
6. Wait for upload (can take 10-30 minutes)

### Step 7: App Store Connect Processing

1. Check email for upload confirmation
2. In App Store Connect:
   - Go to your app
   - TestFlight tab
   - Build will appear in ~10-15 minutes
   - Status: "Processing" → "Ready to Submit"

### Step 8: TestFlight Beta Testing (Recommended)

1. **Internal Testing**
   - Add internal testers (Apple Developer team members)
   - Distributed automatically

2. **External Testing**
   - Create test group
   - Add external testers (up to 10,000)
   - Requires App Review for first build
   - Share public link or invite via email

3. **Collect Feedback**
   - Testers can submit feedback via TestFlight
   - Monitor crash reports

### Step 9: Submit for App Review

1. **Complete App Information**
   - App Privacy: Complete privacy questionnaire
   - Age Rating: Complete questionnaire
   - App Review Information:
     - Contact: Your email and phone
     - Demo Account: Provide test login (if required)
     - Notes: Any special instructions

2. **Pricing and Availability**
   - Price: Select price tier (or free)
   - Availability: Select countries
   - Pre-orders: (Optional)

3. **Select Build**
   - Click "Build" → Select uploaded build

4. **Submit for Review**
   - Click "Add for Review"
   - Click "Submit to App Review"

### Step 10: App Review Process

**Timeline**: 24-48 hours (typically)

**Possible Outcomes:**
1. **Approved** → App goes live automatically (or on release date)
2. **Rejected** → Review rejection reasons, fix, and resubmit

**Common Rejection Reasons:**
- Broken features or crashes
- Missing privacy policy
- Misleading screenshots
- Incomplete app information
- Guideline violations

### Step 11: Post-Release

1. **Monitor Metrics**
   - App Store Connect → Analytics
   - Downloads, sessions, crashes

2. **Respond to Reviews**
   - Monitor user reviews
   - Respond to feedback

3. **Plan Updates**
   - Bug fixes: Submit as soon as possible
   - New features: Plan regular updates

---

## Environment-Specific Configuration

### Development
```swift
// Config.swift
#if DEBUG
static let backendAPIURL = "http://localhost:3000/api"
#else
static let backendAPIURL = "https://your-railway-app.railway.app/api"
#endif
```

### Staging (Optional)

Create separate Railway project for staging:
```bash
railway link staging-project
railway up
```

Separate config:
```swift
#if STAGING
static let backendAPIURL = "https://staging.railway.app/api"
#endif
```

---

## Continuous Deployment

### Backend Auto-Deploy (Railway)

Railway automatically deploys when you push to GitHub:

```bash
git push origin main
# Railway detects push and deploys automatically
```

Configure in Railway:
- Settings → Deployments → Auto-deploy: ON
- Select branch: main

### iOS Auto-Build (Xcode Cloud) (Optional)

1. Enable Xcode Cloud in Xcode
2. Configure workflow:
   - Trigger: On push to main
   - Actions: Archive and export
3. Auto-upload to TestFlight

---

## Rollback Procedures

### Backend Rollback

**Railway:**
1. Go to Deployments tab
2. Find previous successful deployment
3. Click "Redeploy"

**Or via CLI:**
```bash
railway rollback
```

### iOS Rollback

**Cannot rollback App Store releases**, but you can:
1. Submit emergency bug fix update
2. Use phased rollout (pause rollout if issues detected)

**TestFlight:**
- Can add older build back to testing

---

## Monitoring Production

### Backend Monitoring

**Railway Metrics:**
- CPU usage
- Memory usage
- Response times
- Error rates

**Set Up Alerts:**
1. Railway Dashboard → Settings → Notifications
2. Add email or Slack webhook

**External Monitoring:**
- Use services like Uptime Robot or Pingdom
- Monitor `/health` endpoint

### iOS App Monitoring

**App Store Connect Analytics:**
- Crashes
- Sessions
- Engagement

**Third-Party Services:**
- Firebase Crashlytics
- Sentry
- New Relic

---

## Disaster Recovery

### Database Backups

**Railway PostgreSQL:**
- Automatic daily backups
- 7-day retention

**Manual Backup:**
```bash
railway run pg_dump DATABASE_URL > backup.sql
```

**Restore:**
```bash
railway run psql DATABASE_URL < backup.sql
```

### Secrets Management

**Store backups of:**
- All API keys
- Environment variables
- Certificates and keys

**Use a password manager:**
- 1Password
- LastPass
- Bitwarden

---

## Post-Deployment Checklist

- [ ] Backend health check passing
- [ ] Database migrations successful
- [ ] All environment variables set correctly
- [ ] Webhooks configured and tested
- [ ] iOS app connects to production API
- [ ] Authentication works end-to-end
- [ ] Orders can be created
- [ ] Payments process successfully
- [ ] Push notifications working
- [ ] All third-party integrations working
- [ ] Monitoring and alerting configured
- [ ] Team notified of deployment
- [ ] Documentation updated with production URLs
- [ ] Backup and recovery procedures tested

---

## Support and Troubleshooting

### Common Issues

**Issue: Build fails on Railway**
- Check logs in Railway dashboard
- Verify `package.json` scripts
- Ensure all dependencies are listed

**Issue: Database connection fails**
- Verify `DATABASE_URL` is correct
- Check Railway PostgreSQL is running
- Ensure migrations have run

**Issue: iOS app can't connect to API**
- Verify production URL in `Config.swift`
- Check CORS settings on backend
- Ensure HTTPS is working

**Issue: Authentication fails**
- Verify Clerk API keys (publishable vs secret)
- Check token expiration
- Ensure Clerk webhook is configured

---

Congratulations! Your Happy Launderer app is now live in production! 🎉

