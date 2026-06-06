const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const { JWT_SECRET } = require('../middleware/auth');

exports.register = async (req, res) => {
  const { name, email, password, role } = req.body;

  try {
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Check if there are any users in the database
    const userCount = await User.count();
    
    // Auto-promote the very first user to approved Admin so setting up is seamless
    const isFirstUser = userCount === 0;
    const finalRole = isFirstUser ? 'admin' : (role || 'staff');
    const finalStatus = isFirstUser ? 'approved' : 'pending';

    const user = await User.create({
      name,
      email,
      password: hashedPassword,
      role: finalRole,
      status: finalStatus,
    });

    res.status(201).json({
      message: isFirstUser 
        ? 'Admin account created and approved automatically.' 
        : 'Registration successful. Waiting for Admin approval.',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error during registration.', error: error.message });
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials.' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials.' });
    }

    if (user.status === 'pending') {
      return res.status(403).json({ 
        message: 'Your account is pending admin approval.',
        status: 'pending'
      });
    }

    if (user.status === 'rejected') {
      return res.status(403).json({ 
        message: 'Your request has been rejected by Admin.',
        status: 'rejected'
      });
    }

    const token = jwt.sign(
      { id: user.id, role: user.role, pSignature: user.password.substring(0, 15) },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error during login.', error: error.message });
  }
};

// Fetch pending approval requests (Admin Only)
exports.getPendingRequests = async (req, res) => {
  try {
    const pendingUsers = await User.findAll({
      where: { status: 'pending' },
      attributes: { exclude: ['password'] },
    });
    res.json(pendingUsers);
  } catch (error) {
    res.status(500).json({ message: 'Failed to retrieve pending requests.', error: error.message });
  }
};

// Approve or Reject a user registration (Admin Only)
exports.updateRequestStatus = async (req, res) => {
  const { userId, status } = req.body;

  if (!['approved', 'rejected'].includes(status)) {
    return res.status(400).json({ message: 'Invalid status. Must be approved or rejected.' });
  }

  try {
    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ message: 'User request not found.' });
    }

    user.status = status;
    await user.save();

    res.json({ message: `User status updated to ${status}.`, userId: user.id, status: user.status });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update request status.', error: error.message });
  }
};

// Change Password for Currently Logged-In User (Self)
exports.changePassword = async (req, res) => {
  const { oldPassword, newPassword } = req.body;

  try {
    const user = await User.findByPk(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Incorrect current password.' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    res.json({ message: 'Password changed successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to change password.', error: error.message });
  }
};

// Update Profile Details (Self Name/Email update, e.g., to transfer admin account)
exports.updateProfile = async (req, res) => {
  const { name, email } = req.body;

  try {
    const user = await User.findByPk(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    if (email && email !== user.email) {
      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        return res.status(400).json({ message: 'Email is already in use by another account.' });
      }
      user.email = email;
    }

    if (name) {
      user.name = name;
    }

    await user.save();

    res.json({
      message: 'Profile updated successfully.',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update profile.', error: error.message });
  }
};

// Fetch Approved Staff List (Admin Only)
exports.getStaffList = async (req, res) => {
  try {
    const staff = await User.findAll({
      where: { role: 'staff', status: 'approved' },
      attributes: { exclude: ['password'] },
    });
    res.json(staff);
  } catch (error) {
    res.status(500).json({ message: 'Failed to retrieve staff list.', error: error.message });
  }
};

// Delete a Staff Member (Admin Only)
exports.deleteStaff = async (req, res) => {
  const { id } = req.params;

  try {
    const staff = await User.findByPk(id);
    if (!staff) {
      return res.status(404).json({ message: 'Staff member not found.' });
    }

    if (staff.role === 'admin') {
      return res.status(403).json({ message: 'Administrators cannot be deleted.' });
    }

    await staff.destroy();
    res.json({ message: 'Staff member deleted from database successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to delete staff member.', error: error.message });
  }
};

// Admin Override Password Reset for Staff (Admin Only)
exports.adminResetPassword = async (req, res) => {
  const { targetId, newPassword } = req.body;

  try {
    const user = await User.findByPk(targetId);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    if (user.role === 'admin' && user.id !== req.user.id) {
      return res.status(403).json({ message: 'You cannot reset password for other Administrators.' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    res.json({ message: `Password for ${user.name} has been reset successfully.` });
  } catch (error) {
    res.status(500).json({ message: 'Failed to reset password.', error: error.message });
  }
};
