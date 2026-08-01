const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure upload directories exist
const uploadDirs = [
  'uploads/covers',
  'uploads/pdfs',
  'uploads/slips',
  'uploads/kyc',
  'uploads/profiles'
];

uploadDirs.forEach(dir => {
  const fullPath = path.join(__dirname, '..', dir);
  if (!fs.existsSync(fullPath)) {
    fs.mkdirSync(fullPath, { recursive: true });
  }
});

// Configure Multer Disk Storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let dest = 'uploads/covers';

    if (file.fieldname === 'pdf' || file.mimetype === 'application/pdf') {
      dest = 'uploads/pdfs';
    } else if (file.fieldname === 'slip') {
      dest = 'uploads/slips';
    } else if (file.fieldname === 'kyc_doc' || file.fieldname === 'selfie') {
      dest = 'uploads/kyc';
    } else if (file.fieldname === 'profile') {
      dest = 'uploads/profiles';
    }

    cb(null, path.join(__dirname, '..', dest));
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, `${file.fieldname}-${uniqueSuffix}${ext}`);
  }
});

// File Filter
const fileFilter = (req, file, cb) => {
  const allowedImageTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  const allowedPdfTypes = ['application/pdf'];

  if (allowedImageTypes.includes(file.mimetype) || allowedPdfTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only image files (JPG, PNG, WEBP) and PDF documents are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  limits: { fileSize: 100 * 1024 * 1024 }, // Max 100MB
  fileFilter: fileFilter
});

module.exports = upload;
