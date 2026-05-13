const express = require('express');
const cors = require('cors');
const { sequelize } = require('./models');

const authRoutes = require('./routes/authRoutes');
const memberRoutes = require('./routes/memberRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const websiteRoutes = require('./routes/websiteRoutes');
const inquiryRoutes = require('./routes/inquiryRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' })); // Allow larger payloads for Base64 photos

// Serve static landing page files from 'public' folder (reversible/modular)
app.use(express.static('public'));

// API Endpoints
app.use('/api/auth', authRoutes);
app.use('/api/members', memberRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/website', websiteRoutes);
app.use('/api/inquiries', inquiryRoutes);

// Base route for server health check (only active if public/index.html is not found)
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Gym Management Admin API is live and healthy.' });
});

// Database Synchronization and Server Launch
sequelize.sync({ force: false }) // Keep existing tables, alter safely if schemas change
  .then(() => {
    console.log('----------------------------------------------------');
    console.log('🟢 SQLite database synchronized successfully!');
    app.listen(PORT, () => {
      console.log(`🚀 Gym Admin Server is running on: http://localhost:${PORT}`);
      console.log('----------------------------------------------------');
    });
  })
  .catch(err => {
    console.error('🔴 Database sync failed:', err);
  });
