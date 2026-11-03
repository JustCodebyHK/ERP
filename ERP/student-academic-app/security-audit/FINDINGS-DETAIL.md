# Findings Detail — Student Academic ERP Security Audit

Run ID: saa-2026-11-03-01
Source: findings.json (same fingerprints; this file expands the narrative)

---

## F-001 — CORS allows all origins (medium)

**What:** `backend/src/index.js:23` — `app.use(cors())` with no options.
**Why it matters:** The default CORS middleware replies `Access-Control-Allow-Origin: *` to every request. Any origin can make cross-origin requests to the API. The Flutter mobile client sends a bearer JWT on every request; a browser-based client (Flutter Web) or a malicious page could trigger authenticated cross-origin requests.
**Principal:** any website origin.
**Resource:** authenticated API sessions and role-scoped data.
**Fix:** `app.use(cors({ origin: process.env.CORS_ORIGIN }))` and set `CORS_ORIGIN` in render.yaml and `.env`. If no web client exists, consider removing CORS entirely.

---

## F-002 — JWT stored unencrypted in shared_preferences (high)

**What:** `frontend/lib/auth_store.dart:49-58` — `saveSession` writes `token`, `user_id`, `user_name`, `user_email`, `user_role` to `SharedPreferences` in plaintext.
**Why it matters:** `shared_preferences` stores plaintext XML/YAML in the app's private data directory. On a rooted device, via ADB backup, or by a malicious app with storage permission, the bearer JWT is extractable. The token is valid for 7 days (F-006) and is attached to every API request (`frontend/lib/api.dart:59-66`), giving full access to the user's role-scoped resources.
**Principal:** any process with access to shared_preferences.
**Fix:** Encrypt at rest using `flutter_secure_storage` (Android Keystore / iOS Keychain), or at minimum clear tokens on logout and avoid long-lived storage.

---

## F-003 — No rate limiting on auth endpoints (medium)

**What:** `backend/src/routes/auth.js:24-59` (register) and `:62-80` (login); `backend/src/index.js:23-24` has only `cors()` and `express.json()` — no rate-limit middleware.
**Why it matters:** An unauthenticated attacker can send unlimited login/register attempts. With a 6-character password minimum (F-005) and no lockout (F-004), credential stuffing and brute force are practical.
**Fix:** Add `express-rate-limit` to `/api/auth/*` (e.g., 5 requests/min per IP for login, 3/min for register). Keep error messages generic (already done: "Invalid email or password").

---

## F-004 — No account lockout after failed logins (medium)

**What:** `backend/src/routes/auth.js:62-80` — every failed login returns 401 and the next attempt is immediately allowed. No failure counter, lockout, or progressive delay.
**Why it matters:** Removes the primary deterrent to brute force. Combined with F-003, an attacker can iterate passwords without restriction.
**Fix:** Track failed attempts per email/IP; after N failures, lock the account or impose a progressive delay, and require password reset to unlock.

---

## F-005 — Weak password policy (6 characters) (low)

**What:** `backend/src/routes/auth.js:37-39` — `if (!password || password.length < 6)` rejects only below 6 characters.
**Why it matters:** Six-character passwords are trivially brute-forced, especially with no rate limit (F-003) or lockout (F-004).
**Fix:** Enforce 12+ characters and/or block common or breached passwords.

---

## F-006 — No JWT refresh rotation; 7-day static token (low)

**What:** `backend/src/routes/auth.js:11-16` — `jwt.sign({ sub, role, name }, JWT_SECRET, { expiresIn: '7d' })`. No refresh token, no rotation, no revocation list.
**Why it matters:** A stolen token (via F-002, log leak, or client-side issue) is valid for a full week with no way to revoke it short of changing `JWT_SECRET` (which invalidates all sessions).
**Fix:** Short-lived access tokens (e.g., 15 min) plus server-stored, rotated refresh tokens; revoke on logout or suspicious activity.

---

## F-007 — TLS validation disabled for PostgreSQL in production (high)

**What:** `backend/src/db.js:7-10` — `ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false`.
**Why it matters:** In production the `pg` Pool accepts any server certificate. A man-in-the-middle on the API-to-database network path can present a forged certificate, capture `DATABASE_URL` credentials, and read or modify all academic data.
**Fix:** Use `rejectUnauthorized: true` and provide a valid CA, or remove the ssl override so the default verified connection is used.

---

## F-008 — No HTTP security headers (low)

**What:** `backend/src/index.js:20-53` — Express app uses only `cors()` and `express.json()`. No `helmet()` or equivalent.
**Why it matters:** Absence of `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, and `Content-Security-Policy` weakens client-side protections for any web-based client.
**Fix:** Add `app.use(helmet())` with a CSP appropriate for an API backend (at minimum `nosniff` and `DENY`).

---

## F-009 — File upload trusts client MIME type; no magic-byte validation (medium)

**What:** `backend/src/routes/notes.js:16-41` and `assignments.js:14-38` — `multer` `fileFilter` checks `file.mimetype` only (client-settable). Files are stored as `uuidv4() + path.extname(file.originalname)`, where `originalname` is client-controlled. A `.php`/`.asp` file can be uploaded with an `image/jpeg` mime.
**Why it matters:** Currently contained because downloads use `Content-Disposition: attachment`. Becomes high severity (RCE) if `uploads/` is ever served statically or with executable handlers (NV-001).
**Fix:** Validate magic bytes (e.g., `file-type`) against the allow list `{pdf, doc, docx, ppt, pptx, txt, jpg, png}`; reject disallowed extensions; store outside the web root.

---

## F-010 — Parent registration accepts any email domain (informational)

**What:** `backend/src/routes/auth.js:34` — `if (role !== 'parent' && !emailLower.endsWith('@ybit.ac.in'))` exempts parents from the institutional-email requirement.
**Why it matters:** If external parents are intentional, this is by design. If not, any email can register as a parent and link to student data via `/api/parent/link`.
**Fix:** Require `@ybit.ac.in` for all roles, or add email verification before child linking.

---

## F-011 — No email verification after registration (low)

**What:** `backend/src/routes/auth.js:24-59` — register returns a JWT immediately after `INSERT`. No confirmation token, no `email_verified` flag.
**Why it matters:** An attacker can register with an email they do not own and immediately obtain an authenticated session.
**Fix:** Issue an out-of-band confirmation token; set `email_verified` only after the user clicks it; require verification before issuing a JWT.

---

## F-012 — Weak group invite-code entropy (8 hex chars, ~32 bits) (low)

**What:** `backend/src/routes/groups.js:9-11` — `generateInviteCode()` returns `uuidv4().replace(/-/g, '').slice(0, 8).toUpperCase()` — only 8 hex characters.
**Why it matters:** ~32 bits of entropy is guessable, especially with no rate limiting on `/api/groups/join` (F-003 pattern). An attacker could join groups and read messages/membership.
**Fix:** Use 12-16 alphanumeric characters (~64+ bits) and rate-limit `/api/groups/join`.

---

## F-013 — Server errors logged to console (informational)

**What:** `backend/src/index.js:46-49` — the 500 error handler calls `console.error(err)`.
**Why it matters:** Raw `Error` objects may contain stack traces, query text, or environment values in server logs. Clients receive a generic 500, but log readers (and any log aggregation service) see more.
**Fix:** Route errors through a structured logger that sanitizes sensitive fields; never print raw `Error` objects to stdout in production.

---

## Needs validation (referenced from findings.json)

| Fingerprint | Item | Disposition pending |
|-------------|------|---------------------|
| NV-001 | Is `uploads/` served statically/executable? | Could escalate F-009 to high (RCE) |
| NV-002 | Is production `JWT_SECRET` strong and rotated? | Affects F-006 exploitability |
| NV-003 | Are `shared_preferences` extractable on target devices? | Affects real-world impact of F-002 |
| NV-004 | Is brute force feasible against login? | Confirms F-003/F-004 exploitability |

See `NEEDS-VALIDATION.md` for safe, local validation plans for each. None of these were executed because no OS-enforced sandbox was available on this host.

---

## Methodological boundaries

- Static source review only; no builds, tests, fixtures, or live probes were executed.
- Severity follows the skill's anchors; `needs_validation` records carry no severity.
- No findings were inferred from deployment behavior absent from source.
- This report describes fixes; it does not modify target source.
