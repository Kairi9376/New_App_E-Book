const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const { testConnection } = require('./config/db');
const upload = require('./middleware/upload');
const { requireAuth } = require('./middleware/auth');
const { deleteOldFile } = require('./utils/fileUtils');

// Load environment variables
dotenv.config();

// # ເຮັດຫຍັງ: ຢຸດ server ທັນທີຖ້າບໍ່ມີ JWT_SECRET
// # ຍ້ອນຫຍັງ: authController ເຄີຍຂຽນ process.env.JWT_SECRET || 'secret' ເຊິ່ງແປວ່າ
// #          ຖ້າ .env ບໍ່ຖືກໂຫຼດ token ຈະຖືກເຊັນດ້ວຍຄຳວ່າ 'secret' ທີ່ໃຜກໍ່ເດົາໄດ້
// #          ແລ້ວປອມ token ເປັນ admin ໄດ້ທັນທີ - ອັນຕະລາຍກວ່າການທີ່ server ບໍ່ຂຶ້ນ
// # ແກ້ຈາກສ່ວນໃດ: ບໍ່ເຄີຍມີການກວດ env ຕອນ start ເລີຍ
// # ແກ້ເຮັດຫຍັງ: ລົ້ມແຕ່ຕົ້ນພ້ອມຂໍ້ຄວາມຊັດເຈນ ດີກວ່າແລ່ນຢູ່ແບບບໍ່ປອດໄພໂດຍບໍ່ຮູ້ຕົວ
if (!process.env.JWT_SECRET) {
  console.error(
    '❌ ບໍ່ພົບ JWT_SECRET - ສ້າງໄຟລ໌ .env ຢູ່ root ຈາກ .env.example ກ່ອນ\n' +
    '   (ຖ້າແລ່ນຜ່ານ Docker ໃຫ້ກວດວ່າ docker-compose.yml ສົ່ງ JWT_SECRET ເຂົ້າມາ)'
  );
  process.exit(1);
}

const app = express();
const PORT = process.env.PORT || 5000;

// Enable Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve Uploaded Files Static Folder (Access files via <origin>/uploads/...)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// # PUBLIC_BASE_URL = the scheme+host:port EXTERNAL clients (Flutter app,
// # browser) use to reach this backend. It is the ONLY source for building
// # public file URLs. NEVER derive a public URL from process.env.PORT:
// #   INTERNAL:  PORT=5000                    (express listen port inside container)
// #   PUBLIC:    PUBLIC_BASE_URL=http://localhost:5001   (client/host reachable)
// # Docker maps host 5001 -> container 5000; clients never reach 5000 directly.
const PUBLIC_BASE_URL = (process.env.PUBLIC_BASE_URL || '').trim().replace(/\/+$/, '');

// Absolute origin as the CLIENT reached us, taken from the request rather than
// from PORT. Inside Docker the app listens on 5000 but is published on another
// host port, and Android emulators dial 10.0.2.2 instead of localhost - so the
// listen port is never a safe basis for a URL we hand back to a client.
const clientOrigin = (req) => `${req.protocol}://${req.get('host')}`;

// Origin used when handing absolute URLs back to clients. Prefers the explicit
// PUBLIC_BASE_URL so the host:port is stable and correct; falls back to the
// request Host header only when PUBLIC_BASE_URL is not configured.
const publicOrigin = (req) => PUBLIC_BASE_URL || clientOrigin(req);

// Test Database Connection
testConnection();

// Root route & Health check
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to E-Book Application RESTful API',
    status: 'Running',
    database: 'MySQL (phpMyAdmin / XAMPP)',
    static_uploads: `${publicOrigin(req)}/uploads`,
    timestamp: new Date().toISOString()
  });
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', uptime: process.uptime() });
});

// # ເຮັດຫຍັງ: ຕິດ requireAuth ໃສ່ endpoint ອັບໂຫຼດ
// # ຍ້ອນຫຍັງ: ແຕ່ກ່ອນໃຜກໍ່ອັບໄຟລ໌ຂຶ້ນ server ໄດ້ໂດຍບໍ່ຕ້ອງ login
// #          ຮັບໄດ້ເຖິງ 100MB ຕໍ່ໄຟລ໌ ຈຶ່ງເປັນຊ່ອງໃຫ້ຖົມພື້ນທີ່ດິສຈົນເຕັມ
// # ແກ້ຈາກສ່ວນໃດ: app.post('/api/upload', upload.fields([...]) ໂດຍບໍ່ມີການກວດສິດ
// # ແກ້ເຮັດຫຍັງ: ວາງ requireAuth ໄວ້ *ກ່ອນ* multer ເພື່ອປະຕິເສດຕັ້ງແຕ່ກ່ອນຮັບ byte
// #             ບໍ່ແມ່ນຮັບໄຟລ໌ຈົນຄົບແລ້ວຈຶ່ງຄ່ອຍປະຕິເສດ
// Single & Multiple File Upload Endpoint (with automatic old file cleanup)
app.post('/api/upload', requireAuth, upload.fields([
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
          url: `${publicOrigin(req)}/${relativePath}`,
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
  const displayOrigin = PUBLIC_BASE_URL || `http://localhost:${PORT}`;
  console.log(`🚀 E-Book API Server is running on http://localhost:${PORT}`);
  console.log(`📁 Uploads public base: ${displayOrigin}/uploads/`);
});
