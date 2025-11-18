# Contributing to Happy Launderer

Thank you for your interest in contributing to Happy Launderer! This document provides guidelines and instructions for contributing.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Testing Guidelines](#testing-guidelines)
6. [Pull Request Process](#pull-request-process)
7. [Reporting Bugs](#reporting-bugs)
8. [Suggesting Features](#suggesting-features)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

**Positive behaviors include:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behaviors include:**
- Trolling, insulting/derogatory comments, and personal attacks
- Public or private harassment
- Publishing others' private information without permission
- Other conduct which could reasonably be considered inappropriate

---

## Getting Started

### Prerequisites

- Node.js 18+
- PostgreSQL 14+
- Xcode 15.0+
- Git

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork:
```bash
git clone https://github.com/YOUR_USERNAME/happy-launderer.git
cd happy-launderer
```

3. Add upstream remote:
```bash
git remote add upstream https://github.com/ORIGINAL_OWNER/happy-launderer.git
```

### Setup Development Environment

#### Backend

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your development credentials
npm run migrate
npm run dev
```

#### iOS App

```bash
cd ios-app
open HappyLaunderer.xcodeproj
# Build and run in Xcode
```

---

## Development Workflow

### 1. Create a Branch

Always create a new branch for your work:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

**Branch naming conventions:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Adding tests

### 2. Make Your Changes

- Write clean, readable code
- Follow the coding standards (see below)
- Add comments where necessary
- Update documentation if needed

### 3. Commit Your Changes

Write clear, descriptive commit messages:

```bash
git add .
git commit -m "Add feature: user profile picture upload"
```

**Good commit messages:**
- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- First line should be 50 characters or less
- Reference issues: "Fix #123: Handle null user profile"

**Examples:**
```
Add order cancellation feature
Fix payment processing bug on iOS 16
Update API documentation for orders endpoint
Refactor authentication manager
```

### 4. Keep Your Branch Updated

Regularly sync with upstream:

```bash
git fetch upstream
git rebase upstream/main
```

### 5. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

---

## Coding Standards

### Backend (Node.js)

#### JavaScript Style

- Use ES6+ features
- Use `const` and `let`, never `var`
- Use arrow functions when appropriate
- Use template literals for string interpolation

**Example:**
```javascript
// Good
const calculateTotal = (items) => {
  return items.reduce((sum, item) => sum + item.price, 0);
};

// Bad
var calculateTotal = function(items) {
  var sum = 0;
  for (var i = 0; i < items.length; i++) {
    sum = sum + items[i].price;
  }
  return sum;
}
```

#### Error Handling

Always handle errors properly:

```javascript
// Good
async function fetchUser(id) {
  try {
    const user = await db.query('SELECT * FROM users WHERE id = $1', [id]);
    return user.rows[0];
  } catch (error) {
    console.error('Error fetching user:', error);
    throw new Error('Failed to fetch user');
  }
}
```

#### Validation

Always validate input:

```javascript
const schema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(8).required()
});

const { error, value } = schema.validate(req.body);
if (error) throw error;
```

### iOS (Swift)

#### Swift Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Use SwiftUI naming conventions

**Example:**
```swift
// Good
func fetchUserOrders() async throws -> [Order] {
    let response: OrdersResponse = try await apiClient.get(
        endpoint: Config.apiEndpoint("/orders")
    )
    return response.orders
}

// Bad
func getOrders() async throws -> [Order] {
    let r: OrdersResponse = try await apiClient.get(
        endpoint: Config.apiEndpoint("/orders")
    )
    return r.orders
}
```

#### Error Handling

Use Swift's error handling:

```swift
// Good
do {
    let orders = try await orderManager.fetchOrders()
    self.orders = orders
} catch {
    self.errorMessage = error.localizedDescription
    self.showError = true
}
```

#### SwiftUI Best Practices

- Keep views small and focused
- Extract reusable components
- Use `@State`, `@Binding`, `@ObservedObject` appropriately

---

## Testing Guidelines

### Backend Testing

#### Unit Tests

Test individual functions:

```javascript
describe('calculatePrice', () => {
  it('should calculate correct price for standard service', () => {
    const result = calculatePrice('standard');
    expect(result).toBe(25.00);
  });
});
```

#### Integration Tests

Test API endpoints:

```javascript
describe('POST /api/orders', () => {
  it('should create a new order', async () => {
    const response = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${token}`)
      .send(orderData);
    
    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
  });
});
```

### iOS Testing

#### Unit Tests

```swift
func testOrderManagerFetchOrders() async throws {
    let orderManager = OrderManager.shared
    let orders = try await orderManager.fetchOrders()
    XCTAssertNotNil(orders)
}
```

#### UI Tests

```swift
func testLoginFlow() throws {
    let app = XCUIApplication()
    app.launch()
    
    let emailField = app.textFields["Email"]
    emailField.tap()
    emailField.typeText("test@example.com")
    
    // ... continue test
}
```

---

## Pull Request Process

### Before Submitting

1. ✅ Code follows style guidelines
2. ✅ All tests pass
3. ✅ Documentation updated
4. ✅ No lint errors
5. ✅ Commit messages are clear
6. ✅ Branch is up to date with main

### Submitting a Pull Request

1. **Push to your fork:**
```bash
git push origin feature/your-feature-name
```

2. **Open Pull Request on GitHub:**
   - Go to your fork on GitHub
   - Click "Pull Request"
   - Select base: main, compare: your-branch
   - Fill in the PR template

3. **PR Title Format:**
```
[Type] Brief description

Types: Feature, Fix, Docs, Refactor, Test
Example: [Feature] Add user profile picture upload
```

4. **PR Description Template:**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## How to Test
Steps to test the changes

## Screenshots (if applicable)
Add screenshots here

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Commented hard-to-understand code
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests added/updated
- [ ] All tests pass
```

### Code Review Process

1. **Automated Checks:**
   - CI/CD runs tests
   - Linters check code style
   - Must pass before review

2. **Peer Review:**
   - At least one approval required
   - Address all comments
   - Make requested changes

3. **Merge:**
   - Maintainer will merge when approved
   - Branch will be deleted automatically

---

## Reporting Bugs

### Before Reporting

1. Check existing issues
2. Try to reproduce in latest version
3. Gather relevant information

### Bug Report Template

```markdown
**Describe the bug**
A clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen

**Screenshots**
If applicable, add screenshots

**Environment:**
 - Device: [e.g. iPhone 14 Pro]
 - OS: [e.g. iOS 17.0]
 - App Version: [e.g. 1.0.0]

**Additional context**
Any other context about the problem
```

---

## Suggesting Features

### Feature Request Template

```markdown
**Is your feature request related to a problem?**
A clear description of the problem

**Describe the solution you'd like**
A clear description of what you want to happen

**Describe alternatives you've considered**
Alternative solutions or features

**Additional context**
Any other context or screenshots
```

---

## Communication

### Channels

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: Questions, ideas
- **Pull Requests**: Code contributions

### Response Times

- Issues: 1-3 business days
- Pull Requests: 1-5 business days
- Questions: 1-7 days

---

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Recognized in the community

---

## Questions?

If you have questions about contributing, please:
1. Check existing documentation
2. Search closed issues
3. Open a new discussion on GitHub

Thank you for contributing to Happy Launderer! 🎉

