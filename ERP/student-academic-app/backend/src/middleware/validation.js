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


function isSubjectId(value) {  const num = Number(value); if (!Number.isInteger(num) || num <= 0) { return { valid: false, error: 'Invalid subject ID' }; } return { valid: true };}


function isAssignmentId(value) {  const num = Number(value); if (!Number.isInteger(num) || num <= 0) { return { valid: false, error: 'Invalid assignment ID' }; } return { valid: true };}


function isNoteId(value) {  const num = Number(value); if (!Number.isInteger(num) || num <= 0) { return { valid: false, error: 'Invalid note ID' }; } return { valid: true };}


function isSubmissionId(value) {  const num = Number(value); if (!Number.isInteger(num) || num <= 0) { return { valid: false, error: 'Invalid submission ID' }; } return { valid: true };}


function isBatchId(value) {  const num = Number(value); if (!Number.isInteger(num) || num <= 0) { return { valid: false, error: 'Invalid batch ID' }; } return { valid: true };}


function isYear(value) {  const num = Number(value); if (!Number.isInteger(num) || num < 2020 || num > 2030) { return { valid: false, error: 'Invalid year' }; } return { valid: true };}


function isSemester(value) {  if (!['odd', 'even'].includes(value)) { return { valid: false, error: 'Semester must be odd or even' }; } return { valid: true };}


function isSection(value) {  if (!['A', 'B', 'C', 'D'].includes(value)) { return { valid: false, error: 'Invalid section' }; } return { valid: true };}


function isPhone(value) {  if (!/^[0-9]{10}$/.test(value)) { return { valid: false, error: 'Invalid phone number' }; } return { valid: true };}


function isAddress(value) {  if (typeof value !== 'string' || value.length > 200) { return { valid: false, error: 'Address must not exceed 200 characters' }; } return { valid: true };}


function isCity(value) {  if (typeof value !== 'string' || value.length > 50) { return { valid: false, error: 'City must not exceed 50 characters' }; } return { valid: true };}


function isZipCode(value) {  if (!/^[0-9]{5,6}$/.test(value)) { return { valid: false, error: 'Invalid zip code' }; } return { valid: true };}


function isCountry(value) {  if (typeof value !== 'string' || value.length > 50) { return { valid: false, error: 'Invalid country' }; } return { valid: true };}


function isFileSize(value) {  const mb = Number(value); if (!Number.isInteger(mb) || mb < 1 || mb > 100) { return { valid: false, error: 'Invalid file size' }; } return { valid: true };}


function isMimeType(value) {  const allowed = ['application/pdf','image/jpeg','image/png','text/plain']; if (!allowed.includes(value)) { return { valid: false, error: 'Unsupported file type' }; } return { valid: true };}


function isUrl(value) {  try { new URL(value); return { valid: true }; } catch { return { valid: false, error: 'Invalid URL' }; }}


function isDate(value) {  const d = new Date(value); if (isNaN(d.getTime())) { return { valid: false, error: 'Invalid date' }; } return { valid: true };}


function isFutureDate(value) {  const d = new Date(value); if (d <= new Date()) { return { valid: false, error: 'Date must be in the future' }; } return { valid: true };}


function isPastDate(value) {  const d = new Date(value); if (d >= new Date()) { return { valid: false, error: 'Date must be in the past' }; } return { valid: true };}


function isBoolean(value) {  if (typeof value !== 'boolean') { return { valid: false, error: 'Value must be boolean' }; } return { valid: true };}


function isEnum(value) {  const allowed = ['active','inactive','archived']; if (!allowed.includes(value)) { return { valid: false, error: 'Invalid status' }; } return { valid: true };}


function isHexColor(value) {  if (!/^#[0-9A-Fa-f]{6}$/.test(value)) { return { valid: false, error: 'Invalid hex color' }; } return { valid: true };}


function isUuid(value) {  if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(value)) { return { valid: true }; } return { valid: false, error: 'Invalid UUID' }}


function isPort(value) {  const p = Number(value); if (!Number.isInteger(p) || p < 1 || p > 65535) { return { valid: false, error: 'Invalid port' }; } return { valid: true };}


function isLimit(value) {  const n = Number(value); if (!Number.isInteger(n) || n < 1 || n > 100) { return { valid: false, error: 'Limit must be 1-100' }; } return { valid: true };}


function isOffset(value) {  const n = Number(value); if (!Number.isInteger(n) || n < 0) { return { valid: false, error: 'Offset must be non-negative' }; } return { valid: true };}


function isSortOrder(value) {  if (!['asc','desc'].includes(value)) { return { valid: false, error: 'Sort order must be asc or desc' }; } return { valid: true };}


function isLanguage(value) {  if (!['en','es','fr'].includes(value)) { return { valid: false, error: 'Unsupported language' }; } return { valid: true };}


function isTimezone(value) {  try { Intl.DateTimeFormat(undefined, { timeZone: value }); return { valid: true }; } catch { return { valid: false, error: 'Invalid timezone' }; }}


function isCurrency(value) {  if (!/^[A-Z]{3}$/.test(value)) { return { valid: false, error: 'Invalid currency code' }; } return { valid: true };}


function isAmount(value) {  const n = Number(value); if (!Number.isFinite(n) || n < 0) { return { valid: false, error: 'Invalid amount' }; } return { valid: true };}

module.exports = { isEmail, isPassword, isName, isRole, isOptionalString, isPositiveInteger, isNonEmptyArray, validateBody};};};};};};};};};};};};};};};};};};};};};};};};};};};};};};};};};};}; };
