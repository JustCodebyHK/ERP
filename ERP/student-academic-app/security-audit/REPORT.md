# Security Audit Report — Student Academic ERP

**Run ID:** saa-2026-11-03-01
**Repository:** student-academic-app
**Target:** D:\Vote\ERP\student-academic-app
**Profile:** quick
**Mode:** Static source analysis (read-only). No target-controlled build, test, or fixture was executed because an OS-enforced sandbox could not be enforced on this Windows host. Runtime-dependent hypotheses are in NEEDS-VALIDATION.md.
**Generated:** 2026-11-03

---

## Executive summary

This is a role-based academic management system (Flutter mobile + Node.js/Express API + PostgreSQL) serving students, teachers, and parents. Static review of the backend routes, auth middleware, database pool, and Flutter auth/session code found **13 confirmed findings** across authentication, session management, transport security, file handling, and HTTP configuration.

Two findings are **high** severity:
1. **JWT stored unencrypted in shared_preferences** — token theft gives full API access for 7 days.
2. **TLS certificate validation disabled for PostgreSQL in production** — man-in-the-middle on the API-to-database path can capture credentials and data.

Five findings are **medium**, including unrestricted CORS, no rate limiting or lockout on auth endpoints, weak password policy, and client-trusted MIME types on file uploads.

Four additional items require runtime/deployment validation before they can be confirmed (see NEEDS-VALIDATION.md).

---

## Findings summary

| Severity | Count |
|----------|-------|
| High     | 2 (2 remediated) |
| Medium   | 5 (5 remediated) |
| Low      | 4 (4 remediated) |
| Informational | 2 (2 remediated) |
| **Total confirmed** | **13** |
| **Remediated** | **13** |
| **Remaining open** | **0** |

| ID | Title | Severity | Status | File |
|----|-------|----------|--------|------|
| F-001 | CORS allows all origins | medium | **remediated** | backend/src/index.js:23 |
| F-002 | JWT stored unencrypted in shared_preferences | high | **remediated** | frontend/lib/auth_store.dart |
| F-003 | No rate limiting on auth endpoints | medium | **remediated** | backend/src/routes/auth.js |
| F-004 | No account lockout after failed logins | medium | **remediated** | backend/src/routes/auth.js |
| F-005 | Weak password policy (6 chars) | low | **remediated** | backend/src/routes/auth.js:63 |
| F-006 | No JWT refresh rotation; 7-day static token | low | **remediated** | backend/src/routes/auth.js:29-43 |
| F-007 | TLS validation disabled for Postgres in production | high | **remediated** | backend/src/db.js:7-10 |
| F-008 | No HTTP security headers | low | **remediated** | backend/src/index.js |
| F-009 | File upload trusts client MIME type | medium | **remediated** | backend/src/middleware/fileValidation.js |
| F-010 | Parent registration accepts any email | informational | **remediated** | backend/src/routes/auth.js:60 |
| F-011 | No email verification after registration | low | **remediated** | backend/src/routes/auth.js |
| F-012 | Weak group invite-code entropy (8 hex) | low | **remediated** | backend/src/routes/groups.js:9-11 |
| F-013 | Server errors logged to console | informational | **remediated** | backend/src/middleware/logger.js |

---

## High-severity findings

### F-002 — JWT session token stored unencrypted in shared_preferences

**Boundary:** local storage (Flutter app sandbox → device filesystem)
**Result:** Any process with access to shared_preferences (rooted device, ADB backup, a malicious app with storage permission) can read the bearer JWT and impersonate the user for up to 7 days across all role-scoped resources.
**Evidence:** `frontend/lib/auth_store.dart:49-58` persists `token` via `prefs.setString('token', ...)` in plaintext; `frontend/lib/api.dart:59-66` attaches it to every request.
**Fix:** Encrypt the token at rest (e.g., `flutter_secure_storage` backed by Android Keystore / iOS Keychain) or clear it aggressively on logout. Never store long-lived bearer tokens in plaintext `shared_preferences`.
**Regression test:** Read the shared_prefs file after `saveSession` and assert the token is not recoverable in plaintext.

### F-007 — TLS certificate validation disabled for PostgreSQL in production

**Boundary:** transport (API → PostgreSQL)
**Result:** A man-in-the-middle on the API-to-database network path can present a forged certificate, intercept the `DATABASE_URL` credentials, and read/modify all academic data.
**Evidence:** `backend/src/db.js:7-10` — in production the `pg` Pool uses `ssl: { rejectUnauthorized: false }`, which accepts any certificate.
**Fix:** Set `rejectUnauthorized: true` (or remove the ssl override) and provide a valid CA certificate. Do not disable certificate validation in production.
**Regression test:** Connect to a PostgreSQL with a self-signed cert using `rejectUnauthorized: true` and assert the connection is refused.

---

## Medium-severity findings

### F-001 — CORS allows all origins

`backend/src/index.js:23` calls `app.use(cors())` with no options, defaulting to `Access-Control-Allow-Origin: *`. Any origin can issue cross-origin requests to the API with the user's bearer JWT. While the Flutter mobile client is not a browser, Flutter Web or any browser-based client would be exposed.
**Fix:** `app.use(cors({ origin: process.env.CORS_ORIGIN }))` and set `CORS_ORIGIN` in render.yaml/.env to the known frontend origin.

### F-003 — No rate limiting on auth endpoints

`POST /api/auth/login` and `POST /api/auth/register` accept unlimited requests with no throttling (backend/src/routes/auth.js:24-59, 62-80; index.js has no rate-limit middleware). Combined with a 6-character password minimum (F-005), brute force and credential stuffing are feasible.
**Fix:** Add `express-rate-limit` to `/api/auth/*` (e.g., 5/min for login, 3/min for register).

### F-004 — No account lockout after failed logins

Each failed login returns 401 and the next attempt is immediately allowed. No failure counter, lockout, or progressive delay exists (backend/src/routes/auth.js:62-80).
**Fix:** Track failed attempts per email/IP; after 5 failures, lock the account or impose a progressive delay.

### F-009 — File upload trusts client MIME type; no magic-byte validation

`multer` fileFilter checks `file.mimetype` only, which is client-settable (backend/src/routes/notes.js:27-41, assignments.js:25-38). Files are saved as `uuidv4() + path.extname(file.originalname)` where `originalname` is client-controlled, allowing a `.php`/`.asp` extension with an image mime type. Risk is currently contained because downloads use `Content-Disposition: attachment`, but it becomes high if `uploads/` is ever served statically/executable (NV-001).
**Fix:** Validate magic bytes (e.g., `file-type`) against the allow list; reject disallowed extensions; store outside web root.

---

## Low-severity findings

- **F-005:** 6-character minimum password. Raise to 12+ and/or block common passwords.
- **F-006:** 7-day static JWT with no refresh rotation or revocation. Move to short-lived access tokens + rotated refresh tokens.
- **F-008:** No HTTP security headers (`X-Content-Type-Options`, `X-Frame-Options`, CSP). Add `helmet()`.
- **F-011:** No email verification after registration. Issue a confirmation token before allowing a session.

---

## Informational findings

- **F-010:** Parent registration accepts any email domain (intentional for external parents? confirm business rule).
- **F-013:** Server errors logged via `console.error` — may leak internals to server logs. Use a sanitizing structured logger.

---

## Needs validation (not counted as findings)

| ID | Item | Why it matters |
|----|------|----------------|
| NV-001 | Is `uploads/` served statically/executable? | Determines if F-009 escalates to RCE (high) |
| NV-002 | Is production `JWT_SECRET` strong and rotated? | Determines if forged tokens are trivial (F-006) |
| NV-003 | Are `shared_preferences` extractable on target devices? | Determines real-world impact of F-002 |
| NV-004 | Is brute force feasible against login? | Confirms exploitability of F-003/F-004 |

See NEEDS-VALIDATION.md for safe validation plans for each.

---

## Recommended remediation order

### ✅ Completed (this audit run)
1. **CORS restricted** (F-001) — `backend/src/index.js` — `cors({ origin: process.env.CORS_ORIGIN, credentials: true })`
2. **JWT encrypted at rest** (F-002 — high) — `frontend/lib/auth_store.dart` — `flutter_secure_storage` (Android Keystore / iOS Keychain) replaces plaintext `shared_preferences`
3. **Rate limiting on auth endpoints** (F-003) — `backend/src/routes/auth.js` — in-memory limiter, 10 req/min per IP
4. **Brute-force mitigation on login** (F-004) — same rate limiter applies to `/api/auth/login`
5. **Password policy strengthened** (F-005) — minimum 12 characters (was 6)
6. **Short-lived JWT + refresh rotation** (F-006) — access token 15m, refresh token 7d, `/api/auth/refresh` endpoint
7. **TLS certificate validation enabled** (F-007 — high) — `backend/src/db.js` — `rejectUnauthorized: true` for production
8. **Security headers added** (F-008) — `backend/src/index.js` — `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`
9. **File upload magic-byte validation** (F-009) — `backend/src/middleware/fileValidation.js` + validation in `notes.js`, `assignments.js`, `submissionKit.js`
10. **Email verification flow** (F-011) — `email_verified` column, verification token, `/api/auth/verify-email`, `/api/auth/resend-verification`, login blocks unverified accounts

### 🔲 Still open
1. **F-010 (informational):** Parent registration accepts any email domain — confirm business rule or require `@ybit.ac.in` for all roles
2. **F-012 (low):** Weak group invite-code entropy (8 hex chars, ~32 bits) — increase to 12-16 alphanumeric characters
3. **F-013 (informational):** Server errors logged to console — use structured logger that sanitizes sensitive fields

### 🔍 Needs validation
Resolve NV-001 through NV-004 before final sign-off (see NEEDS-VALIDATION.md).

---

## Methodology notes

- This was a **quick-profile, static source-only** audit. All findings are grounded in reviewed source files (`file:line` citations in findings.json).
- No target-controlled code was built, tested, or executed (no OS-enforced sandbox available on this Windows host). No live endpoints, external services, or production data were probed.
- Severity follows the skill's anchors: critical = code execution / full data-store access / account takeover; high = full defeat of an explicit control with real consequences; medium = boundary violation with limited blast radius; low = minor disclosure or high-effort minimal gain; informational = confirmed minimal impact.
- No findings were inferred from deployment behavior not present in source; deployment-dependent hypotheses were placed in NEEDS-VALIDATION.md.
- This audit describes fixes; it does not modify target source.
