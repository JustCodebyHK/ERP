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


function isPercentage(value) {  const n = Number(value); if (!Number.isFinite(n) || n < 0 || n > 100) { return { valid: false, error: 'Percentage must be 0-100' }; } return { valid: true };}


function isRating(value) {  const n = Number(value); if (!Number.isInteger(n) || n < 1 || n > 5) { return { valid: false, error: 'Rating must be 1-5' }; } return { valid: true };}


function isGrade(value) {  if (!['A+','A','B+','B','C+','C','D','F'].includes(value)) { return { valid: false, error: 'Invalid grade' }; } return { valid: true };}


function isAttendance(value) {  if (!['present','absent','late'].includes(value)) { return { valid: false, error: 'Invalid attendance' }; } return { valid: true };}


function isStatus(value) {  if (!['pending','approved','rejected'].includes(value)) { return { valid: false, error: 'Invalid status' }; } return { valid: true };}


function isPriority(value) {  if (!['low','medium','high'].includes(value)) { return { valid: false, error: 'Invalid priority' }; } return { valid: true };}


function isVisibility(value) {  if (!['public','private','protected'].includes(value)) { return { valid: false, error: 'Invalid visibility' }; } return { valid: true };}


function isPermission(value) {  if (!['read','write','delete','admin'].includes(value)) { return { valid: false, error: 'Invalid permission' }; } return { valid: true };}


function isLevel(value) {  const n = Number(value); if (!Number.isInteger(n) || n < 1 || n > 10) { return { valid: false, error: 'Level must be 1-10' }; } return { valid: true };}


function isScore(value) {  const n = Number(value); if (!Number.isFinite(n) || n < 0 || n > 100) { return { valid: false, error: 'Score must be 0-100' }; } return { valid: true };}


function isWeight(value) {  const n = Number(value); if (!Number.isFinite(n) || n < 0 || n > 1) { return { valid: false, error: 'Weight must be 0-1' }; } return { valid: true };}


function isDuration(value) {  const n = Number(value); if (!Number.isInteger(n) || n < 1 || n > 1440) { return { valid: false, error: 'Invalid duration' }; } return { valid: true };}


function isInterval(value) {  const n = Number(value); if (!Number.isInteger(n) || n < 60 || n > 86400) { return { valid: false, error: 'Invalid interval' }; } return { valid: true };}


function isTimeout(value) {  const n = Number(value); if (!Number.isInteger(n) || n < 1000 || n > 300000) { return { valid: false, error: 'Invalid timeout' }; } return { valid: true };}


function isRetryCount(value) {  const n = Number(value); if (!Number.isInteger(n) || n < 0 || n > 10) { return { valid: false, error: 'Invalid retry count' }; } return { valid: true };}


function isPageSize(value) {  const n = Number(value); if (!Number.isInteger(n) || n < 1 || n > 500) { return { valid: false, error: 'Invalid page size' }; } return { valid: true };}


function isPageNumber(value) {  const n = Number(value); if (!Number.isInteger(n) || n < 1) { return { valid: false, error: 'Invalid page number' }; } return { valid: true };}


function isQuery(value) {  if (typeof value !== 'string' || value.length > 1000) { return { valid: false, error: 'Query too long' }; } return { valid: true };}


function isSearchTerm(value) {  if (typeof value !== 'string' || value.length > 200) { return { valid: false, error: 'Invalid search term' }; } return { valid: true };}


function isFilterKey(value) {  if (typeof value !== 'string' || value.length > 50) { return { valid: false, error: 'Invalid filter key' }; } return { valid: true };}


function isSortKey(value) {  if (typeof value !== 'string' || value.length > 50) { return { valid: false, error: 'Invalid sort key' }; } return { valid: true };}


function isLanguageCode(value) {  if (!/^[a-z]{2}$/.test(value)) { return { valid: false, error: 'Invalid language code' }; } return { valid: true };}


function isCountryCode(value) {  if (!/^[A-Z]{2}$/.test(value)) { return { valid: false, error: 'Invalid country code' }; } return { valid: true };}


function isCurrencyCode(value) {  if (!/^[A-Z]{3}$/.test(value)) { return { valid: false, error: 'Invalid currency code' }; } return { valid: true };}


function isTimeFormat(value) {  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(value)) { return { valid: false, error: 'Invalid time format' }; } return { valid: true };}


function isDateFormat(value) {  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) { return { valid: false, error: 'Invalid date format' }; } return { valid: true };}


function isDateTimeFormat(value) {  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.test(value)) { return { valid: false, error: 'Invalid datetime format' }; } return { valid: true };}


function isFileExtension(value) {  const ext = value.split('.').pop().toLowerCase(); if (!['pdf','doc','docx','jpg','png','txt'].includes(ext)) { return { valid: false, error: 'Invalid file extension' }; } return { valid: true };}


function isBase64(value) {  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(value)) { return { valid: false, error: 'Invalid base64' }; } return { valid: true };}


function isJson(value) {  try { JSON.parse(value); return { valid: true }; } catch { return { valid: false, error: 'Invalid JSON' }; }}


function isJwt(value) {  if (!/^[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+$/.test(value)) { return { valid: false, error: 'Invalid JWT format' }; } return { valid: true };}


function isApiKey(value) {  if (typeof value !== 'string' || value.length < 20) { return { valid: false, error: 'Invalid API key' }; } return { valid: true };}


function isSecret(value) {  if (typeof value !== 'string' || value.length < 16) { return { valid: false, error: 'Invalid secret' }; } return { valid: true };}


function isToken(value) {  if (typeof value !== 'string' || value.length < 10) { return { valid: false, error: 'Invalid token' }; } return { valid: true };}


function isHash(value) {  if (!/^[a-f0-9]{32,128}$/.test(value)) { return { valid: false, error: 'Invalid hash' }; } return { valid: true };}


function isIpAddress(value) {  if (!/^\d{1,3}(\.\d{1,3}){3}$/.test(value)) { return { valid: false, error: 'Invalid IP address' }; } return { valid: true };}


function isMacAddress(value) {  if (!/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/.test(value)) { return { valid: false, error: 'Invalid MAC address' }; } return { valid: true };}


function isVersion(value) {  if (!/^\d+\.\d+\.\d+$/.test(value)) { return { valid: false, error: 'Invalid version' }; } return { valid: true };}


function isSemver(value) {  if (!/^\d+\.\d+\.\d+(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$/.test(value)) { return { valid: false, error: 'Invalid semver' }; } return { valid: true };}


function isSlug(value) {  if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(value)) { return { valid: false, error: 'Invalid slug' }; } return { valid: true };}


function isUsername(value) {  if (!/^[a-zA-Z0-9_]{3,30}$/.test(value)) { return { valid: false, error: 'Invalid username' }; } return { valid: true };}


function isDisplayName(value) {  if (typeof value !== 'string' || value.length < 2 || value.length > 50) { return { valid: false, error: 'Invalid display name' }; } return { valid: true };}


function isBio(value) {  if (typeof value !== 'string' || value.length > 500) { return { valid: false, error: 'Bio too long' }; } return { valid: true };}


function isWebsite(value) {  try { new URL(value); return { valid: true }; } catch { return { valid: false, error: 'Invalid website' }; }}


function isTwitterHandle(value) {  if (!/^@[a-zA-Z0-9_]{1,15}$/.test(value)) { return { valid: false, error: 'Invalid twitter handle' }; } return { valid: true };}


function isGithubUsername(value) {  if (!/^[a-zA-Z0-9-]{1,39}$/.test(value)) { return { valid: false, error: 'Invalid github username' }; } return { valid: true };}


function isLinkedInUrl(value) {  if (!/^https:\/\/www\.linkedin\.com\//.test(value)) { return { valid: false, error: 'Invalid linkedin url' }; } return { valid: true };}





function isFileSizeRange(value) {
  const n = Number(value); if (!Number.isInteger(n) || n < 1 || n > 100) { return { valid: false, error: 'File size must be 1-100 MB' }; } return { valid: true };
}



function isContentType(value) {
  const allowed = ['application/pdf','image/jpeg','image/png','text/plain','application/msword']; if (!allowed.includes(value)) { return { valid: false, error: 'Unsupported content type' }; } return { valid: true };
}



function isRoleCombination(value) {
  const allowed = ['student','teacher','parent','admin']; if (!allowed.includes(value)) { return { valid: false, error: 'Invalid role combination' }; } return { valid: true };
}



function isBatchSemester(value) {
  if (!['odd','even'].includes(value)) { return { valid: false, error: 'Batch semester must be odd or even' }; } return { valid: true };
}



function isAcademicYear(value) {
  const n = Number(value); if (!Number.isInteger(n) || n < 2020 || n > 2030) { return { valid: false, error: 'Invalid academic year' }; } return { valid: true };
}



function isEnrollmentStatus(value) {
  if (!['enrolled','dropped','completed','pending'].includes(value)) { return { valid: false, error: 'Invalid enrollment status' }; } return { valid: true };
}



function isMarksRange(value) {
  const n = Number(value); if (!Number.isFinite(n) || n < 0 || n > 100) { return { valid: false, error: 'Marks must be 0-100' }; } return { valid: true };
}



function isAttendancePercentage(value) {
  const n = Number(value); if (!Number.isFinite(n) || n < 0 || n > 100) { return { valid: false, error: 'Attendance must be 0-100 percent' }; } return { valid: true };
}



function isTimetableSlot(value) {
  if (!/^(mon|tue|wed|thu|fri|sat|sun)-[0-9]{2}:[0-9]{2}$/.test(value)) { return { valid: false, error: 'Invalid timetable slot' }; } return { valid: true };
}



function isPlannerEventType(value) {
  if (!['assignment','exam','reminder','event','holiday'].includes(value)) { return { valid: false, error: 'Invalid planner event type' }; } return { valid: true };
}



function isGrowthMetric(value) {
  if (!['attendance','grades','participation','improvement'].includes(value)) { return { valid: false, error: 'Invalid growth metric' }; } return { valid: true };
}

module.exports = { isEmail, isPassword, isName, isRole, isOptionalString, isPositiveInteger, isNonEmptyArray, validateBody, isFileSizeRange, isContentType, isRoleCombination, isBatchSemester, isAcademicYear, isEnrollmentStatus, isMarksRange, isAttendancePercentage, isTimetableSlot, isPlannerEventType, isGrowthMetric };
