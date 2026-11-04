# Changelog

## [1.0.0] - 2026-11-04

### Added
- Initial release of Student Academic App
- Authentication: register, login, email verification, token refresh
- Role-based access: Student, Teacher, Parent
- Groups: create, invite members (16-char codes), manage membership
- Assignments: upload, submit, download with magic-bytes validation
- Notes: subject-based notes with file upload/download
- Submission Kit: front page, index page, certificate templates
- Security: JWT (15m access + 7d refresh), rate limiting, security headers
- File validation: magic-bytes checking (F-009) replacing MIME-type filters
- Mobile APK: release and debug builds
- Health check endpoints: uptime, memory, CPU, summary, ready, live
- Validation middleware: 50+ validator functions
- Auth middleware: rate limiting, token blacklist, optional auth, role checks
- Database migrations: 14 versioned migrations
- Backend scripts: migrate, seed, and test utilities
- Flutter frontend: models, services, API client, auth store

### Security
- Email verification required before login
- IP-based rate limiting (10 req/60s on auth routes)
- Password minimum 12 characters
- All emails must end with @ybit.ac.in
- Baseline security headers on all responses

### Files
- app-release.apk — Signed release build
- app-debug.apk — Debug build for development