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

    const ext = path.extname(file.originalname).toLowerCase();
    if (file.fieldname === 'pdf' || file.mimetype === 'application/pdf' || ext === '.pdf') {
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

// # ເຮັດຫຍັງ: ຮັດກຸມ fileFilter ໃຫ້ຮັບສະເພາະນາມສະກຸນທີ່ອະນຸຍາດເທົ່ານັ້ນ
// # ຍ້ອນຫຍັງ: ຂອງເກົ່າຜ່ານໄດ້ 5 ທາງ ໂດຍ 2 ທາງສຸດທ້າຍເປີດກວ້າງເກີນໄປ:
// #          application/octet-stream ແມ່ນ MIME ທົ່ວໄປທີ່ browser ສົ່ງມາຕອນເດົາ
// #          ຊະນິດບໍ່ໄດ້ ແລະ !ext ຍອມຮັບໄຟລ໌ບໍ່ມີນາມສະກຸນເລີຍ ຈຶ່ງອັບ .sh .js
// #          ຫຼື ໄຟລ໌ໃດກໍ່ໄດ້ຂຶ້ນ server ໂດຍພຽງແຕ່ຕັ້ງຊື່ໃຫ້ຖືກ
// # ແກ້ຈາກສ່ວນໃດ: ເງື່ອນໄຂ if ທີ່ຕໍ່ດ້ວຍ || 4 ຄັ້ງ
// # ແກ້ເຮັດຫຍັງ: ບັງຄັບໃຫ້ນາມສະກຸນຢູ່ໃນ allowedExts ສະເໝີ ແລ້ວຈຶ່ງກວດ MIME ຄວບຄູ່
// #             (ໄຟລ໌ໃນ uploads/ ຖືກ serve ເປັນ static ບໍ່ໄດ້ຖືກ execute
// #              ແຕ່ການຈຳກັດແຕ່ຕົ້ນຍັງດີກວ່າ ເພາະກັນການໃຊ້ server ເປັນບ່ອນຝາກໄຟລ໌)
const fileFilter = (req, file, cb) => {
  const allowedExts = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.pdf'];
  const ext = path.extname(file.originalname).toLowerCase();

  const extOk = allowedExts.includes(ext);
  const mimeOk =
    file.mimetype.startsWith('image/') ||
    file.mimetype === 'application/pdf' ||
    // browser ບາງໂຕສົ່ງ octet-stream ມາພ້ອມນາມສະກຸນທີ່ຖືກຕ້ອງ - ຍອມຮັບໄດ້
    // ຕໍ່ເມື່ອນາມສະກຸນຜ່ານແລ້ວເທົ່ານັ້ນ (extOk ຖືກກວດຄູ່ກັນຢູ່ດ້ານລຸ່ມ)
    file.mimetype === 'application/octet-stream';

  if (extOk && mimeOk) {
    cb(null, true);
  } else {
    cb(new Error('Only image files (JPG, PNG, WEBP, GIF) and PDF documents are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  limits: { fileSize: 100 * 1024 * 1024 }, // Max 100MB
  fileFilter: fileFilter
});

module.exports = upload;
