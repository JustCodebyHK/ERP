# Hallmark UI Redesign — Student Academic ERP

**Theme:** Ink (manual deal, genre editorial)
**Scope:** Login screen (hero) + student home subjects tab + design-system theme
**Method:** Hallmark Floor rules translated from CSS/HTML to Flutter/Dart
**Preserved:** All API endpoints, auth flow, role routing, caching, offline handling, file upload/download, notifications

---

## What changed

### 1. `frontend/lib/widgets/app_theme.dart` — Hallmark token block

- **Stamp line** added as line 1 (Hallmark v2.0.0, theme Ink).
- **Token block**: every colour and font declared as a named Dart constant before any usage (`seedBrand`, `surface`, `primary`, `onSurface`, `fontBody`, `fontHead`, `spaceXs`…`spaceXxl`, `touchTarget`, `radiusSm`…`radiusLg`, `motionDuration`).
- **No literal colour past the token block** — all surfaces, primaries, errors, labels derive from `ColorScheme` tokens.
- **One weight, one colour for heads** — `FontWeight.w600`, `onSurface`; no italic mixed into roman headings.
- **Labels in body face** — `Inter`, a step smaller, sentence case, untracked (`letterSpacing: 0`), never monospace.
- **Focus colour token** (`focusColor`) + `focusDecoration()` helper for focus-visible on interactives.
- **`prefersReducedMotion(BuildContext)`** — reads `MediaQuery.disableAnimations`; consumers shorten or disable animation.
- **One radius per nesting level** — `radiusSm`/`Md`/`Lg`.
- Waived Floor rules noted in the stamp comment (rule 4 overflow-x clip, rule 7 scripting-off not applicable to Flutter).

### 2. `frontend/lib/screens/login_screen.dart` — hero redesign

- **Stamp line** as line 1.
- **Capped, centred container** — `BoxConstraints(maxWidth: 400)`, centred in `SafeArea`/`Center`.
- **Hero visible without scrolling** — headline (7 words), one sentence (12 words), one primary filled button + one secondary text button; all fields visible on a small phone.
- **≤80 words** on the screen.
- **Focus nodes** on email/password/name fields with `textInputAction` chaining (next → done → submit).
- **Focus-visible suffix icon** on the password toggle (`FocusNode(skipTraversal: true)`).
- **Reduced-motion aware** progress indicator (`AlwaysStoppedAnimation` when `prefersReducedMotion`).
- **No invented metrics** — no fake stat counts, no emoji icons.
- **One primary button style** (filled), one secondary (text).

### 3. `frontend/lib/screens/student_home.dart` — literal colours removed

- `_MoreTile` colour chips now use `context.cs.primary` / `context.cs.secondary` / `context.cs.tertiary` instead of `Colors.green` / `deepOrange` / `purple` / `teal`.
- `_getSubjectColor(BuildContext, int)` returns theme colour-scheme tokens instead of literal `Colors.indigo` / `blue` / `teal` / `purple` / `deepOrange` / `green` / `pink` / `amber`.

---

## What remains (future Hallmark passes)

All screens have been tokenized. The following screens had literal `Colors.*` values replaced with `ColorScheme` tokens:

- `frontend/lib/widgets/common_widgets.dart` — `Colors.white` → `context.cs.onPrimary`
- `frontend/lib/models/announcement.dart` — type color map → `AppTheme` tokens
- `frontend/lib/models/growth.dart` — `statusColor` → `AppTheme` tokens
- `frontend/lib/models/group.dart` — `typeColor` → `AppTheme` tokens
- `frontend/lib/models/parent.dart` — `typeColors` → `AppTheme` tokens
- `frontend/lib/models/planner.dart` — `priorityColor` → `AppTheme` tokens
- `frontend/lib/screens/group_chat.dart` — all message bubble/role colors → `context.cs.*`
- `frontend/lib/screens/student_groups.dart` — group type colors → `context.cs.*` / `AppTheme.*`
- `frontend/lib/screens/growth_screen.dart` — all component colors → `context.cs.*`
- `frontend/lib/screens/student_home.dart` — subject card colors → `context.cs.*`
- `frontend/lib/screens/student_notes.dart` — file colors → `AppTheme` tokens; UI greys → `context.cs.onSurfaceVariant`
- `frontend/lib/screens/student_timetable.dart` — empty state greys → `context.cs.onSurfaceVariant`
- `frontend/lib/screens/student_announcements.dart` — alert/type chip colors → `context.cs.*` / `AppTheme.*`
- `frontend/lib/screens/student_submission_kit.dart` — current chip → `AppTheme.*`
- `frontend/lib/screens/parent_children.dart` — empty state greys → `context.cs.onSurfaceVariant`
- `frontend/lib/screens/parent_child_overview.dart` — all status/alert colors → `context.cs.*`
- `frontend/lib/screens/teacher_home.dart` — class card text → `context.cs.onPrimary`
- `frontend/lib/screens/teacher_notes.dart` — file colors → `AppTheme` tokens; error/delete → `AppTheme.error` / `context.cs.error`
- `frontend/lib/screens/teacher_submission_kit.dart` — current chip → `AppTheme.*`
- `frontend/lib/screens/teacher_groups.dart` — all role/type colors → `context.cs.*` / `AppTheme.*`
- `frontend/lib/screens/teacher_announcements.dart` — alert banner → `context.cs.error` / `AppTheme.error`
- `frontend/lib/screens/teacher_assignments.dart` — submission status chips → `context.cs.*`
- `frontend/lib/screens/planner_screen.dart` — all status/priority colors → `context.cs.*`

Only `Colors.transparent` remains (2 occurrences: `app_theme.dart:274` bottom sheet background, `teacher_home.dart:337` DraggableScrollableSheet). This is a structural "no background" value, not a design color, and is appropriate for Flutter bottom sheets.

---

## Sweep status (Hallmark Step 7)

- `flutter analyze` could not be run (no Flutter SDK in this environment).
- Floor rule 1 (no literal color past token block) — satisfied for all design colors.
- Floor rule 6 (focus-visible) — applied via focus nodes + `focusDecoration()` helper in login screen.
- Floor rule 7 (reduced motion) — wired via `prefersReducedMotion()`; applied to login progress indicator.

## Material ask

All token slots are defined. The single piece of material that would most improve the page: **real screenshots of the running app** (login, student home subjects grid) to validate the hero posture at device scale.
