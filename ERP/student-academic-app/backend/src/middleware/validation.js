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

function isRole(value) {
  const allowed = ['student', 'teacher', 'parent'];
  if (!allowed.includes(value)) {
    return { valid: false, error: 'Role must be one of: student, teacher, parent' };
  }
  return { valid: true };
}

function isOptionalString(value, maxLen = 500) {
  if (value === undefined || value === null || value === '') {
    return { valid: true };
  }
  if (typeof value !== 'string') {
    return { valid: false, error: 'Value must be a string' };
  }
  if (value.length > maxLen) {
    return { valid: false, error: 'Value must not exceed 500 characters' };
  }
  return { valid: true };
}

function isPositiveInteger(value) {
  const num = Number(value);
  if (!Number.isInteger(num) || num <= 0) {
    return { valid: false, error: 'Value must be a positive integer' };
  }
  return { valid: true };
}

function isNonEmptyArray(value) {
  if (!Array.isArray(value) || value.length === 0) {
    return { valid: false, error: 'Value must be a non-empty array' };
  }
  return { valid: true };
}

function validateBody(rules) {
  return (req, res, next) => {
    const errors = {};
    for (const [field, validator] of Object.entries(rules)) {
      const result = validator(req.body[field]);
      if (!result.valid) {
        errors[field] = result.error;
      }
    }
    if (Object.keys(errors).length > 0) {
      return res.status(400).json({ error: 'Validation failed', fields: errors });
    }
    next();
  };
}



function isStudentId(value) {  const num = Number(value); if (!Number.isInteger(num) || num <= 0 || num > 999999) { return { valid: false, error: 'Invalid student ID' }; } return { valid: true };}


function isTeacherId(value) {  const num = Number(value); if (!Number.isInteger(num) || num <= 0 || num > 999999) { return { valid: false, error: 'Invalid teacher ID' }; } return { valid: true };}


function isParentId(value) {  const num = Number(value); if (!Number.isInteger(num) || num <= 0 || num > 999999) { return { valid: false, error: 'Invalid parent ID' }; } return { valid: true };}


function isGroupId(value) {  const num = Number(value); if (!Number.isInteger(num) || num <= 0) { return { valid: false, error: 'Invalid group ID' }; } return { valid: true };}

module.exports = { isEmail, isPassword, isName, isRole, isOptionalString, isPositiveInteger, isNonEmptyArray, validateBody};};};}; };
