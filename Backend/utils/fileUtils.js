const fs = require('fs');
const path = require('path');

/**
 * Normalizes a file URL or path to a relative upload path e.g. "uploads/covers/image.jpg"
 */
function getRelativeUploadPath(fileUrlOrPath) {
  if (!fileUrlOrPath || typeof fileUrlOrPath !== 'string') return '';
  
  let decoded = decodeURIComponent(fileUrlOrPath).trim();
  let normalized = decoded.replace(/\\/g, '/');

  if (normalized.includes('/uploads/')) {
    return 'uploads/' + normalized.split('/uploads/')[1];
  } else if (normalized.startsWith('uploads/')) {
    return normalized;
  } else if (normalized.includes('uploads/')) {
    return 'uploads/' + normalized.split('uploads/')[1];
  }
  return '';
}

/**
 * Checks if two file paths/URLs refer to the same physical file.
 */
function isSameFilePath(file1, file2) {
  const p1 = getRelativeUploadPath(file1);
  const p2 = getRelativeUploadPath(file2);
  if (!p1 || !p2) return false;
  return p1 === p2;
}

/**
 * Safely deletes an old file from the server's uploads directory.
 * Robustly handles full URLs, relative paths, URL encoding, and path slashes.
 *
 * @param {string} fileUrlOrPath - URL or path of the file to delete
 */
function deleteOldFile(fileUrlOrPath) {
  if (!fileUrlOrPath || typeof fileUrlOrPath !== 'string') return;

  try {
    let relativePath = getRelativeUploadPath(fileUrlOrPath);
    if (!relativePath) return;

    // Fix potential singular 'uploads/pdf/' vs plural 'uploads/pdfs/' path alias
    if (relativePath.startsWith('uploads/pdf/')) {
      relativePath = relativePath.replace('uploads/pdf/', 'uploads/pdfs/');
    }

    // Resolve absolute path on server disk
    const absolutePath = path.resolve(__dirname, '..', relativePath);
    const uploadsDir = path.resolve(__dirname, '..', 'uploads');

    // Security check: Ensure target path is inside uploads directory
    if (!absolutePath.startsWith(uploadsDir)) {
      console.warn(`⚠️ Blocked attempt to delete file outside uploads dir: ${absolutePath}`);
      return;
    }

    // Check if file exists and delete
    if (fs.existsSync(absolutePath)) {
      fs.unlinkSync(absolutePath);
      console.log(`🗑️ Successfully deleted old file from disk: ${absolutePath}`);
    } else {
      console.log(`ℹ️ File to delete was not found on disk: ${absolutePath}`);
    }
  } catch (error) {
    console.error(`❌ Error deleting old file (${fileUrlOrPath}):`, error.message);
  }
}

module.exports = {
  deleteOldFile,
  getRelativeUploadPath,
  isSameFilePath
};
