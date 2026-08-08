const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const { testConnection } = require('./config/db');
const upload = require('./middleware/upload');
const { deleteOldFile } = require('./utils/fileUtils');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Enable Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve Uploaded Files Static Folder (Access files via <origin>/uploads/...)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Absolute origin as the CLIENT reached us, taken from the request rather than
// from PORT. Inside Docker the app listens on 5000 but is published on another
// host port, and Android emulators dial 10.0.2.2 instead of localhost - so the
// listen port is never a safe basis for a URL we hand back to a client.
const clientOrigin = (req) => `${req.protocol}://${req.get('host')}`;

// Test Database Connection
testConnection();

// Root route & Health check
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to E-Book Application RESTful API',
    status: 'Running',
    database: 'MySQL (phpMyAdmin / XAMPP)',
    static_uploads: `${clientOrigin(req)}/uploads`,
    timestamp: new Date().toISOString()
  });
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', uptime: process.uptime() });
});

// Single & Multiple File Upload Endpoint (with automatic old file cleanup)
app.post('/api/upload', upload.fields([
  { name: 'cover', maxCount: 1 },
  { name: 'pdf', maxCount: 1 },
  { name: 'slip', maxCount: 1 },
  { name: 'kyc_doc', maxCount: 1 },
  { name: 'selfie', maxCount: 1 },
  { name: 'profile', maxCount: 1 }
]), (req, res) => {
  try {
    const files = req.files;
    const responseData = {};

    for (const key in files) {
      if (files[key] && files[key].length > 0) {
        const file = files[key][0];
        // Create relative URL path
        const relativePath = path.relative(__dirname, file.path).replace(/\\/g, '/');
        responseData[key] = {
          filename: file.filename,
          url: `${clientOrigin(req)}/${relativePath}`,
          path: relativePath,
          size: file.size
        };
      }
    }

    res.json({
      success: true,
      message: 'File(s) uploaded successfully',
      uploads: responseData
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Upload error', error: error.message });
  }
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
  console.log(`📁 Uploads available at http://localhost:${PORT}/uploads/`);
});
