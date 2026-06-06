const jwt = require('jsonwebtoken');
const { User } = require('../models');

const JWT_SECRET = 'GYM_SECRET_TOKEN_KEY_123'; // Standard static key for local running convenience

// Middleware to verify if user has a valid JWT token and is approved
const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Access denied. No token provided.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findByPk(decoded.id);

    if (!user) {
      return res.status(401).json({ message: 'User session has been deleted or disabled by Admin.' });
    }

    if (user.status !== 'approved') {
      return res.status(403).json({ message: 'Account is pending admin approval.' });
    }

    // Security check: invalidate token if user's password signature changed (reset by admin or updated by self)
    if (decoded.pSignature && decoded.pSignature !== user.password.substring(0, 15)) {
      return res.status(401).json({ message: 'Your password was changed. Please log in again.' });
    }

    req.user = user;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Invalid token.' });
  }
};

// Middleware to restrict action only to Admins
const authorizeAdmin = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    res.status(403).json({ message: 'Require Admin credentials.' });
  }
};

module.exports = {
  authenticate,
  authorizeAdmin,
  JWT_SECRET,
};
