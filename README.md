# Campus - Nigerian University Student Super-App

Flutter (Android-first) + Supabase (auth, Postgres, RLS, storage, realtime, Edge Functions) + Groq (AI, server-side only).

## Layout
- `supabase/migrations/` - ordered SQL migrations (run in order)
- `supabase/seed.sql` - FICTIONAL development data only
- `app/` - Flutter client (feature-first: `lib/core`, `lib/features/<domain>/{data,domain,presentation}`)

## Setup
1. Supabase SQL editor: run `0001_foundation.sql`, `0002_profile_integrity.sql`, then (dev only) `seed.sql`.
2. In `app/`: `flutter create . --platforms=android` (generates `android/`), then `flutter pub get`.
3. Copy `app/.env.example` to `app/.env`, fill in values (never commit it).
4. `flutter run --dart-define-from-file=.env`

## Build status
- Phase 1 done: DB foundation (university structure, profiles, roles, blocks, reports, audit, RLS); Flutter skeleton; email auth.
- Phase 2 done: onboarding (university/faculty/department/programme/level), profile view/edit, privacy controls, bottom-nav shell.
- Next: Phase 3 academics (courses, GPA/CGPA, timetable, planner).
- Later: learning + Q&A, communities + messaging, Groq AI (Edge Function), tutoring + marketplace, opportunities, campus services, admin, tests, docs.
