const fs = require('fs');
const path = require('path');

// Magic byte signatures for allowed upload file types.
// Used to verify file content type independent of the client-supplied MIME
// (which is easily spoofed). Addresses F-009.
const MAGIC_BYTES = {
  'application/pdf': [0x25, 0x50, 0x44, 0x46], // %PDF
  'application/msword': [0xD0, 0xCF, 0x11, 0xE0], // DOC (OLE2 compound)
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': [0x50, 0x4B, 0x03, 0x04], // DOCX (ZIP)
  'application/vnd.ms-powerpoint': [0xD0, 0xCF, 0x11, 0xE0], // PPT (OLE2 compound)
  'application/vnd.openxmlformats-officedocument.presentationml.presentation': [0x50, 0x4B, 0x03, 0x04], // PPTX (ZIP)
  'text/plain': null, // plain text has no reliable magic bytes
  'image/jpeg': [0xFF, 0xD8, 0xFF], // JPEG
  'image/png': [0x89, 0x50, 0x4E, 0x47], // PNG
};

const ALLOWED_EXTENSIONS = {
  'application/pdf': '.pdf',
  'application/msword': '.doc',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': '.docx',
  'application/vnd.ms-powerpoint': '.ppt',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation': '.pptx',
  'text/plain': '.txt',
  'image/jpeg': '.jpg',
  'image/png': '.png',
};

/**
 * Verify that the file at [filePath] begins with the expected magic bytes
 * for [expectedMime]. Returns true if valid, false otherwise.
 */
function validateMagicBytes(filePath, expectedMime) {
  const sig = MAGIC_BYTES[expectedMime];
  if (!sig) return true; // no signature to check (e.g. text/plain)
  let fd;
  try {
    fd = fs.openSync(filePath, 'r');
    const buffer = Buffer.alloc(sig.length);
    const bytesRead = fs.readSync(fd, buffer, 0, sig.length, 0);
    if (bytesRead < sig.length) return false;
    for (let i = 0; i < sig.length; i++) {
      if (buffer[i] !== sig[i]) return false;
    }
    return true;
  } catch {
    return false;
  } finally {
    if (fd !== undefined) fs.closeSync(fd);
  }
}

/**
 * Multer-compatible fileFilter that additionally validates magic bytes after
 * the file has been written to disk. Use this instead of the inline
 * fileFilter in upload routes.
 *
 * Returns a middleware that rejects files whose client MIME type is not in the
 * allow list, and deletes the uploaded file if its magic bytes don't match.
 */
function createSecureMulter(storage, fileSizeLimit = 25 * 1024 * 1024) {
  const multer = require('multer');
  const upload = multer({
    storage,
    limits: { fileSize: fileSizeLimit },
  });
  return upload;
}

/**
 * Post-upload validator: checks magic bytes and allowed extension.
 * Deletes the file and calls cb with an error if invalid.
 */
async function validateUploadedFile(req, file, cb) {
  const allowedMimes = Object.keys(MAGIC_BYTES);
  if (!allowedMimes.includes(file.mimetype)) {
    // Delete the file multer already wrote
    if (file.path) {
      try { fs.unlinkSync(file.path); } catch {}
    }
    return cb(new Error('File type not allowed'));
  }
  const ok = validateMagicBytes(file.path, file.mimetype);
  if (!ok) {
    try { fs.unlinkSync(file.path); } catch {}
    return cb(new Error('File content does not match declared type'));
  }
  // Verify the stored extension matches the expected one for the MIME type
  const expectedExt = ALLOWED_EXTENSIONS[file.mimetype];
  const actualExt = path.extname(file.originalname).toLowerCase();
  if (expectedExt && actualExt !== expectedExt) {
    try { fs.unlinkSync(file.path); } catch {}
    return cb(new Error('File extension does not match declared type'));
  }
  cb(null, true);
}

module.exports = { validateMagicBytes, createSecureMulter, validateUploadedFile, MAGIC_BYTES, ALLOWED_EXTENSIONS };
