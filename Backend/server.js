const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { testConnection } = require('./config/db');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Enable Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Test Database Connection
testConnection();

// Root route & Health check
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to E-Book Application RESTful API',
    status: 'Running',
    database: 'MySQL (phpMyAdmin / XAMPP)',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', uptime: process.uptime() });
});

// Import & Mount Routes (13 Tables API Endpoint Groups)
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/kyc', require('./routes/kycRoutes'));
app.use('/api/authors', require('./routes/authorRoutes'));
app.use('/api/categories', require('./routes/categoryRoutes'));
app.use('/api/books', require('./routes/bookRoutes'));
app.use('/api/packages', require('./routes/packageRoutes'));
app.use('/api/subscriptions', require('./routes/subscriptionRoutes'));
app.use('/api/bookmarks', require('./routes/bookmarkRoutes'));
app.use('/api/history', require('./routes/historyRoutes'));
app.use('/api/downloads', require('./routes/downloadRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/audit-logs', require('./routes/auditLogRoutes'));

// 404 Route Handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'API Route Not Found' });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('Unhandled Error:', err);
  res.status(500).json({ success: false, message: 'Internal Server Error', error: err.message });
});

// Start Express Server
app.listen(PORT, () => {
  console.log(`🚀 E-Book API Server is running on http://localhost:${PORT}`);
});
