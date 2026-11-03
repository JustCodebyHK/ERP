// Input validation middleware for student-academic-app backend
// All validators return { valid: boolean, error?: string }

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function isEmail(value) {
  if (typeof value !== 'string' || !value.trim()) {
    return { valid: false, error: 'Email is required' };
  }
  if (!EMAIL_RE.test(value.trim())) {
    return { valid: false, error: 'Invalid email format' };
  }
  return { valid: true };
}

module.exports = { isEmail };
