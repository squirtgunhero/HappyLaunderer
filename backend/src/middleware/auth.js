const { clerkClient } = require('@clerk/clerk-sdk-node');

/**
 * Middleware to verify Clerk authentication token
 */
async function verifyClerkToken(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No authorization token provided' });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    try {
      // Verify the session token with Clerk
      const session = await clerkClient.sessions.verifySession(token);
      
      if (!session) {
        return res.status(401).json({ error: 'Invalid session' });
      }

      // Get user details from Clerk
      const user = await clerkClient.users.getUser(session.userId);
      
      // Attach user info to request
      req.user = {
        clerkId: user.id,
        email: user.emailAddresses[0]?.emailAddress,
        firstName: user.firstName,
        lastName: user.lastName
      };

      next();
    } catch (clerkError) {
      console.error('Clerk verification error:', clerkError);
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
  } catch (error) {
    console.error('Auth middleware error:', error);
    return res.status(500).json({ error: 'Authentication error' });
  }
}

/**
 * Middleware to check if user is an admin
 */
async function requireAdmin(req, res, next) {
  try {
    const user = await clerkClient.users.getUser(req.user.clerkId);
    
    if (!user.publicMetadata?.role || user.publicMetadata.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required' });
    }

    next();
  } catch (error) {
    console.error('Admin check error:', error);
    return res.status(500).json({ error: 'Authorization error' });
  }
}

/**
 * Middleware to check if user is a driver
 */
async function requireDriver(req, res, next) {
  try {
    const user = await clerkClient.users.getUser(req.user.clerkId);
    
    const role = user.publicMetadata?.role;
    if (!role || (role !== 'driver' && role !== 'admin')) {
      return res.status(403).json({ error: 'Driver access required' });
    }

    next();
  } catch (error) {
    console.error('Driver check error:', error);
    return res.status(500).json({ error: 'Authorization error' });
  }
}

module.exports = {
  verifyClerkToken,
  requireAdmin,
  requireDriver
};

