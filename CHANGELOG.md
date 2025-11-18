# Changelog

All notable changes to the Happy Launderer project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned Features
- WebSocket support for real-time order updates
- In-app chat with customer support
- Loyalty rewards program
- Subscription plans
- Widget support for iOS home screen
- Multi-language support

---

## [1.0.0] - 2024-01-01

### Added - Initial Release

#### Backend
- RESTful API with Express.js
- PostgreSQL database with migrations
- Clerk authentication integration
- Stripe payment processing
- Order management system
- User profile management
- Address management
- Pricing calculation endpoint
- Rate limiting and security middleware
- Comprehensive error handling
- API documentation

#### iOS App
- SwiftUI-based user interface
- MVVM architecture
- Clerk authentication integration
- User registration and login
- Profile management
- Order creation workflow
- Order tracking with real-time updates
- MapKit integration for driver location
- Service type selection (Standard, Express, Premium)
- Payment method management
- Push notification support
- Settings and preferences

#### Features
- **Authentication & Onboarding**
  - Email/password authentication via Clerk
  - User profile setup with name, phone, and address
  - Saved addresses management
  
- **Order Management**
  - Create new laundry orders
  - Select pickup and delivery addresses
  - Schedule pickup time
  - Choose service type (Standard $25, Express $40, Premium $60)
  - Add order notes
  - View order history
  - Track active orders
  - Cancel orders
  - Real-time order status updates
  
- **Order Tracking**
  - Seven order statuses: pending, picked_up, in_laundry, ready, out_for_delivery, completed, cancelled
  - Status history timeline
  - Driver location tracking on map (when out for delivery)
  - Order details view
  
- **Payments**
  - Stripe payment integration
  - Payment method management
  - Automatic payment processing on order creation
  - Payment history
  - Webhook support for payment status updates
  
- **Notifications**
  - Push notification infrastructure
  - Notification settings
  - Order status update notifications
  
- **User Experience**
  - Clean, modern UI design
  - Intuitive navigation with tab bar
  - Pull-to-refresh on lists
  - Loading states and error handling
  - Smooth animations and transitions

#### Documentation
- Comprehensive README
- Setup guide
- API documentation
- Architecture documentation
- Deployment guide
- Contributing guidelines

#### Security
- HTTPS for all API communication
- JWT-based authentication
- Rate limiting (100 requests per 15 minutes)
- Input validation with Joi
- SQL injection prevention with parameterized queries
- CORS configuration
- Helmet security headers

#### Developer Experience
- Environment variable configuration
- Database migrations
- Seeded sample data support
- API health check endpoint
- Comprehensive error messages
- Logging with Morgan

---

## Version History

### Version Numbering

We use Semantic Versioning:
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality (backwards compatible)
- **PATCH** version for bug fixes (backwards compatible)

Example: `1.2.3`
- 1 = Major version
- 2 = Minor version
- 3 = Patch version

---

## Types of Changes

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

---

## Future Releases

### [1.1.0] - Planned
- Enhanced driver tracking with route display
- In-app notifications center
- Order search and filtering
- Payment receipt generation
- Customer support chat

### [1.2.0] - Planned
- Loyalty program implementation
- Referral system
- Multiple payment methods support
- Scheduled recurring orders
- Order preferences and favorites

### [2.0.0] - Planned
- WebSocket real-time updates
- GraphQL API (breaking change)
- Offline mode support
- Advanced analytics dashboard
- Multi-language support

---

## Links

- [GitHub Repository](https://github.com/yourusername/happy-launderer)
- [Documentation](./docs/)
- [API Documentation](./docs/API_DOCUMENTATION.md)
- [Contributing Guidelines](./docs/CONTRIBUTING.md)

---

*For detailed information about each release, see the full release notes on GitHub.*

