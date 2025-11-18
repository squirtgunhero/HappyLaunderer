# TestFlight Deployment Guide

This guide walks you through deploying the Happy Launderer iOS app to TestFlight for beta testing.

---

## Prerequisites

### Required Accounts & Tools

1. **Apple Developer Account** ($99/year)
   - Sign up: https://developer.apple.com/programs/
   - Must be enrolled and active
   - Verify at: https://developer.apple.com/account/

2. **macOS with Xcode**
   - Download from Mac App Store
   - Version 14.0+ recommended
   - Command Line Tools installed

3. **App Store Connect Access**
   - Access: https://appstoreconnect.apple.com/
   - Same Apple ID as Developer account

---

## Step 1: Configure Your Xcode Project

### 1.1 Open Project in Xcode

```bash
cd "/Users/michaelehrlich/Desktop/Happy Launderer/ios-app"
open -a Xcode .
```

Or create an Xcode project:

```bash
# If you haven't created an Xcode project yet
cd ios-app
# Create a new Xcode project with:
# - Product Name: HappyLaunderer
# - Team: Your Apple Developer team
# - Organization Identifier: com.yourcompany (e.g., com.happylaunderer)
# - Bundle Identifier: com.yourcompany.happylaunderer
# - Interface: SwiftUI
# - Language: Swift
```

### 1.2 Configure Bundle Identifier

1. Select your project in Xcode (blue icon at top)
2. Select the **HappyLaunderer** target
3. Go to **General** tab
4. Set **Bundle Identifier**: `com.yourcompany.happylaunderer` (must be unique)
5. Set **Version**: `1.0.0`
6. Set **Build**: `1`

### 1.3 Configure Signing & Capabilities

1. Stay in **General** tab
2. Under **Signing & Capabilities**:
   - ✅ Check **Automatically manage signing**
   - Select your **Team** (Apple Developer account)
   - Xcode will create provisioning profile automatically

3. Add Required Capabilities:
   - Click **+ Capability** button
   - Add: **Push Notifications**
   - Add: **Background Modes** → Enable: Remote notifications
   - Add: **Sign in with Apple** (if using Clerk with Apple login)

### 1.4 Set Deployment Target

1. In **General** tab
2. Set **Minimum Deployments**: iOS 16.0 (or higher)

---

## Step 2: Configure App Information

### 2.1 Update Config.swift

Make sure your `Config.swift` has production values:

```swift
enum Config {
    static let apiBaseURL = "https://your-production-api.com" // Update this!
    static let clerkPublishableKey = "pk_live_xxxxx" // Use LIVE key for production
}
```

### 2.2 Update Info.plist

Ensure `Info.plist` has required permissions:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes for order tracking</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby pickup/delivery options</string>

<key>NSUserTrackingUsageDescription</key>
<string>We use tracking to improve your experience and show relevant offers</string>
```

---

## Step 3: Create App in App Store Connect

### 3.1 Log into App Store Connect

1. Go to https://appstoreconnect.apple.com/
2. Click **My Apps**
3. Click **+** (plus icon) → **New App**

### 3.2 Fill in App Information

**Platforms**: ✅ iOS

**Name**: `Happy Launderer` (or your preferred name)
- This is the public-facing name
- Can be changed later

**Primary Language**: English (or your language)

**Bundle ID**: Select the one you configured in Xcode
- Should be: `com.yourcompany.happylaunderer`
- If not showing, go to Apple Developer → Identifiers → Create new

**SKU**: `happylaunderer-001` (unique identifier, not public)
- Just needs to be unique in your account

**User Access**: Full Access

Click **Create**

---

## Step 4: Fill in App Store Information

After creating the app, fill in required information:

### 4.1 App Information

1. Go to **App Information** (left sidebar)
2. Fill in:
   - **Category**: Primary: Lifestyle, Secondary: Business
   - **Content Rights**: Your information
   - **Age Rating**: Select appropriate ratings

### 4.2 Pricing and Availability

1. Go to **Pricing and Availability**
2. Set **Price**: Free (or your price)
3. Set **Availability**: All countries (or specific)

### 4.3 App Privacy

1. Go to **App Privacy**
2. Click **Get Started**
3. Answer questions about data collection:
   - **Contact Info**: Yes (email, name, phone)
   - **Location**: Yes (for delivery tracking)
   - **Payment Info**: Yes (for Stripe)
   - **User Content**: Yes (laundry preferences)
   
4. For each data type, specify:
   - How it's used (app functionality, payment processing)
   - Whether it's linked to user
   - Whether it's used for tracking

---

## Step 5: Archive and Upload Your App

### 5.1 Select Device Target

1. In Xcode, at top near play/stop buttons
2. Select **Any iOS Device (arm64)** or **Generic iOS Device**
3. Do NOT select Simulator

### 5.2 Archive the App

1. In Xcode menu: **Product** → **Archive**
2. Wait for build to complete (may take 5-10 minutes)
3. Organizer window will open automatically

If archive fails, check:
- ✅ Signing configured correctly
- ✅ No build errors
- ✅ "Any iOS Device" selected (not Simulator)

### 5.3 Upload to App Store Connect

1. In **Organizer** window (should open after archive)
   - If not open: Window → Organizer → Archives
2. Select your archive
3. Click **Distribute App**
4. Select **App Store Connect**
5. Select **Upload**
6. Configure options:
   - ✅ Include bitcode for iOS: No (deprecated)
   - ✅ Upload your app's symbols: Yes
   - ✅ Manage Version and Build Number: (Xcode managed)
7. Select signing: **Automatically manage signing**
8. Click **Upload**
9. Wait for upload to complete (5-20 minutes depending on size)

---

## Step 6: Submit Build to TestFlight

### 6.1 Wait for Processing

1. Go to App Store Connect → Your App
2. Click **TestFlight** tab
3. Under **iOS Builds**, wait for "Processing" to complete
   - Usually takes 10-30 minutes
   - You'll get email when ready

### 6.2 Add Export Compliance

Once processing completes:

1. Click on the build number (e.g., `1.0.0 (1)`)
2. Answer **Export Compliance** questions:
   - "Is your app designed to use cryptography?"
   - Answer: **Yes** (using HTTPS)
   - "Does your app contain encryption?"
   - Answer: **No** (if only using standard HTTPS, no custom encryption)
3. Save

### 6.3 Add Test Information

1. Still in build details
2. Add **What to Test** notes:
   ```
   Please test:
   - User registration and login
   - Creating a new order
   - Selecting pickup/delivery addresses
   - Payment processing (use Stripe test cards)
   - Order tracking
   - Push notifications
   
   Test Credentials:
   Email: test@example.com
   Password: TestPassword123!
   
   Stripe Test Card: 4242 4242 4242 4242
   ```

---

## Step 7: Add Testers

### 7.1 Internal Testing (Immediate)

Internal testers can test immediately (no review):

1. In **TestFlight** tab
2. Click **Internal Testing** (left sidebar)
3. Click **+** next to **Internal Testers**
4. Add testers by email (must have App Store Connect access)
5. Testers receive invitation email immediately

### 7.2 External Testing (Requires Review)

External testers need Apple review (1-2 days):

1. In **TestFlight** tab
2. Under **External Testing**, click **+** (Add Group)
3. Create group: "Beta Testers"
4. Add build to group
5. Fill in **Test Information**:
   - **What to Test**: Description for reviewers
   - **Email**: Your contact email
   - **Phone**: Your contact phone
   - **Sign-In Required**: Yes
   - **Test Account**: Provide test credentials
   
6. Click **Submit for Review**
7. Wait 1-2 business days for approval

### 7.3 Add Individual Testers

After group is approved:

1. Click the test group
2. Click **+** next to **Testers**
3. Add by email address
4. Or create a **Public Link** (anyone with link can join)

---

## Step 8: Testers Install the App

### 8.1 Tester Setup

Testers need:

1. **TestFlight app** installed (from App Store)
2. **Invitation email** from TestFlight
3. Click **View in TestFlight** button in email
4. Or enter **Redeem Code** in TestFlight app

### 8.2 Installing the Beta

1. Open TestFlight app
2. Select "Happy Launderer"
3. Tap **Install**
4. App installs like normal App Store app
5. Can provide feedback through TestFlight

---

## Step 9: Update Your Beta

### 9.1 Make Changes

```bash
cd "/Users/michaelehrlich/Desktop/Happy Launderer/ios-app"
# Make your code changes
```

### 9.2 Increment Build Number

In Xcode:
1. Select project → Target → General
2. Increment **Build** number (e.g., `1` → `2`)
3. Keep Version same (e.g., `1.0.0`) unless major changes

### 9.3 Archive and Upload Again

1. Product → Archive
2. Distribute → Upload
3. Wait for processing
4. Testers automatically notified of update

---

## Troubleshooting

### Archive Not Showing

**Problem**: Archive doesn't appear in Organizer

**Solution**:
- Ensure "Any iOS Device" selected (not Simulator)
- Check for build errors
- Try: Product → Clean Build Folder
- Try: Delete DerivedData folder

### Signing Errors

**Problem**: "Failed to create provisioning profile"

**Solution**:
- Verify Apple Developer membership is active
- Check Bundle ID is registered in Developer Portal
- Try: Uncheck/recheck "Automatically manage signing"
- Try: Xcode → Preferences → Accounts → Download Manual Profiles

### Upload Fails

**Problem**: Upload to App Store Connect fails

**Solution**:
- Check internet connection
- Verify App Store Connect is online (check status page)
- Try Application Loader (legacy tool)
- Verify Xcode is up to date

### Processing Stuck

**Problem**: Build stuck on "Processing" for hours

**Solution**:
- Wait 24 hours (sometimes takes this long)
- Check App Store Connect notifications for errors
- Contact Apple Developer Support if > 24 hours

### Missing Compliance

**Problem**: "Missing Compliance" warning

**Solution**:
- Answer Export Compliance questions
- For HTTPS only: Select "No" for custom encryption
- Save and wait a few minutes

---

## TestFlight Limits

### Internal Testing
- **Max testers**: 100
- **Review required**: No
- **Immediate access**: Yes
- **Who can test**: App Store Connect users only

### External Testing
- **Max testers**: 10,000
- **Review required**: Yes (first build only, or major changes)
- **Review time**: 1-2 business days
- **Who can test**: Anyone with email/public link

### Build Limits
- **Expiration**: 90 days after upload
- **Max builds**: No limit (but only 100 can be active)
- **Max apps**: No limit per account

---

## Best Practices

### 1. Test Internally First

Always test with internal testers before external:
- Catch major bugs before review
- Faster iteration (no review needed)
- Use your development team

### 2. Provide Good Test Notes

Help testers know what to test:
```
Version 1.0.0 (Build 1)
- NEW: User registration flow
- NEW: Order booking system
- FIXED: Payment processing bugs
- TEST: Focus on payment flow with test card 4242...
```

### 3. Use Test Credentials

Provide test accounts in TestFlight notes:
- Email and password
- Pre-loaded data if needed
- Stripe test card numbers

### 4. Increment Builds Properly

- **Build number**: Increment for every upload (1, 2, 3...)
- **Version number**: Change for major updates (1.0.0 → 1.1.0)

### 5. Monitor Feedback

Check TestFlight regularly:
- Tester feedback
- Crash reports
- Screenshots from testers

### 6. Keep Builds Current

- Builds expire after 90 days
- Upload new builds regularly
- Remove old builds from testing

---

## Next Steps After TestFlight

Once beta testing is complete:

### 1. Prepare for App Store

1. Take screenshots (required sizes)
2. Write App Store description
3. Create app icon (1024x1024)
4. Make preview video (optional)

### 2. Submit for App Store Review

1. In App Store Connect → Your App
2. Click **App Store** tab (not TestFlight)
3. Create **new version** (1.0)
4. Fill in all required information
5. Submit for review
6. Wait 1-7 days for approval

### 3. Release

- Choose **Manual Release** or **Automatic** after approval
- Monitor reviews and ratings
- Respond to user feedback

---

## Useful Links

- **App Store Connect**: https://appstoreconnect.apple.com/
- **Apple Developer**: https://developer.apple.com/account/
- **TestFlight Documentation**: https://developer.apple.com/testflight/
- **App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **System Status**: https://developer.apple.com/system-status/

---

## Support

If you run into issues:

1. **Apple Developer Forums**: https://developer.apple.com/forums/
2. **Stack Overflow**: Tag with `ios`, `testflight`, `xcode`
3. **Apple Developer Support**: Contact through Developer Portal
4. **Xcode Documentation**: Help → Developer Documentation

---

**Good luck with your TestFlight deployment!** 🚀

Once your beta testing is complete and you're ready for the App Store, see `docs/APP_STORE_SUBMISSION.md`.

