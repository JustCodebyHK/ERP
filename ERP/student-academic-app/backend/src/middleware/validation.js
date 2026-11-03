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

function isPassword(value) {
  if (typeof value !== 'string' || !value) {
    return { valid: false, error: 'Password is required' };
  }
  if (value.length < 12) {
    return { valid: false, error: 'Password must be at least 12 characters' };
  }
  return { valid: true };
}

function isName(value) {
  if (typeof value !== 'string' || !value.trim()) {
    return { valid: false, error: 'Name is required' };
  }
  if (value.trim().length < 2) {
    return { valid: false, error: 'Name must be at least 2 characters' };
  }
  if (value.trim().length > 100) {
    return { valid: false, error: 'Name must not exceed 100 characters' };
  }
  return { valid: true };
}

module.exports = { isEmail, isPassword, isName };
