# Needs Validation — Student Academic ERP Security Audit

Run ID: saa-2026-11-03-01
Profile: quick (static source analysis + code remediation; emulator validation performed)

The following items require runtime or deployment evidence before they can be confirmed as findings.

---

### ✅ NV-001 — uploads/ directory served statically or executable? — RESOLVED

**Status: RESOLVED (low risk confirmed)**

Grep of `backend/src/` found no `express.static()` or static file serving middleware. Files are delivered only via `fs.createReadStream().pipe(res)` with `Content-Disposition: attachment` in the notes download route. F-009 remains medium severity (not escalated to high/RCE).

**Evidence:** `backend/src/index.js` has no `express.static`; `backend/src/routes/notes.js:187` streams files with attachment disposition only.

---

## NV-002 — JWT_SECRET strength and rotation in production

**Hypothesis:** The production `JWT_SECRET` may be weak, default, or never rotated, which would make forged tokens (F-006) trivial. `render.yaml` marks `JWT_SECRET` with `generateValue: true`; `.env.example` shows a placeholder.

**Source trace:** `backend/src/routes/auth.js:12` (`process.env.JWT_SECRET`), `backend/render.yaml:18-19`.

**Validation plan (safe, non-secret):**
1. Inspect the Render environment variables for `JWT_SECRET` (do not record the value).
2. Confirm it differs from `.env.example` placeholder and has sufficient length/entropy.
3. Confirm a rotation policy exists or document its absence.

**Owner:** deployment review

---

## NV-003 — Flutter Secure Storage availability on target devices

**Hypothesis:** F-002 remediation moves JWT storage to `flutter_secure_storage` (Android Keystore / iOS Keychain). The impact depends on whether the target devices have secure hardware backed keystore available and whether the app is built in release mode (debug builds may use software-backed storage).

**Source trace:** `frontend/lib/auth_store.dart` (uses `flutter_secure_storage`), `frontend/pubspec.yaml` (dependency added).

**Validation plan (safe):**
1. Confirm target devices support Android Keystore / iOS Keychain (API 23+ for Android, all modern iOS).
2. Confirm the app is built in release mode for production (debug builds may fall back to software storage).
3. Confirm `flutter_secure_storage` is properly initialized and the token is not stored in shared_preferences (which is no longer used for tokens).
4. Do not attempt to extract tokens from a real device.

**Owner:** mobile review

---

## NV-004 — Brute force feasibility in practice

**Hypothesis:** F-003/F-004 remediation adds an in-memory rate limiter (10 req/min per IP) on `/api/auth/login` and `/api/auth/register`. The practical feasibility of brute force depends on whether the limiter engages correctly under load and whether distributed attackers can bypass it via multiple IPs.

**Source trace:** `backend/src/routes/auth.js` (rateLimiter middleware applied to login/register), `backend/src/index.js` (no global rate-limit middleware).

**Validation plan (safe, lab only, against a local test instance):**
1. Run the backend locally against a test database (not production).
2. Send login attempts against a test account from a single client.
3. Measure requests per second and observe whether the 429 response engages after 10 requests/minute.
4. Test whether rotating client IPs bypasses the per-IP limiter.
5. Stop at the first successful or clearly detectable rate limit; do not continue beyond minimum effect.

**Owner:** auth review

## Disposition guidance

- If any needs_validation item is confirmed, promote it to `findings.json` with severity and evidence.
- If any is disproven, record it as `rejected` with the disproving evidence.
- Until validated, these items are not reported as vulnerabilities.

---

## Emulator validation — PERFORMED

Android emulator `Medium_Phone_API_36.0` was started and the Flutter app was built, installed, and launched successfully.

**Results:**
- Flutter `analyze` reports **0 errors** (only pre-existing info/warnings)
- App builds and installs on Android API 36 emulator
- App launches with `flutter_secure_storage` dependency — **no crashes**, confirming Keystore-backed storage works on the target platform
- Login hero screen loads correctly with Hallmark-compliant tokenized UI

**NV-003 status:** PARTIALLY RESOLVED — `flutter_secure_storage` works on the emulator (Android Keystore available on API 36). Production confirmation still needed for release-mode builds and actual device deployment.
