-- 0001_foundation.sql
-- Phase 1: extensions, enums, academic structure, profiles, roles, blocks, reports, audit logs, RLS.

create extension if not exists pgcrypto;
create extension if not exists citext;
create extension if not exists pg_trgm;

-- ───────────── Enums ─────────────
create type public.app_role as enum (
  'super_admin','platform_admin','university_admin','faculty_admin','department_admin',
  'community_moderator','content_moderator','opportunity_manager','marketplace_moderator'
);
create type public.profile_visibility as enum ('public','university','private');
create type public.message_permission as enum ('everyone','university','nobody');
create type public.verification_status as enum ('unverified','pending','verified','rejected');
create type public.moderation_status as enum ('pending','approved','flagged','removed');
create type public.report_status as enum ('open','reviewing','resolved','dismissed');
create type public.report_target as enum (
  'user','post','comment','listing','opportunity','message','question','answer','service','accommodation','other'
);

-- ───────────── Helpers ─────────────
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

-- ───────────── Academic structure ─────────────
create table public.countries (
  code char(2) primary key,
  name text not null unique
);

create table public.universities (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references public.countries(code),
  name text not null,
  short_name text,
  slug text not null unique,
  website text,
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index universities_name_trgm on public.universities using gin (name gin_trgm_ops);

create table public.campuses (
  id uuid primary key default gen_random_uuid(),
  university_id uuid not null references public.universities(id) on delete cascade,
  name text not null,
  city text,
  state text,
  unique (university_id, name)
);

create table public.faculties (
  id uuid primary key default gen_random_uuid(),
  university_id uuid not null references public.universities(id) on delete cascade,
  name text not null,
  unique (university_id, name)
);

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  faculty_id uuid not null references public.faculties(id) on delete cascade,
  name text not null,
  unique (faculty_id, name)
);

-- Configurable grading: grades = [{"letter":"A","min":70,"points":5.0}, ...]
create table public.grading_schemes (
  id uuid primary key default gen_random_uuid(),
  university_id uuid references public.universities(id) on delete cascade, -- null = platform default
  name text not null,
  max_points numeric(3,1) not null check (max_points > 0),
  grades jsonb not null check (jsonb_typeof(grades) = 'array'),
  is_default boolean not null default false
);

create table public.programmes (
  id uuid primary key default gen_random_uuid(),
  department_id uuid not null references public.departments(id) on delete cascade,
  name text not null,
  duration_years smallint not null default 4 check (duration_years between 1 and 8),
  grading_scheme_id uuid references public.grading_schemes(id),
  unique (department_id, name)
);

create table public.academic_sessions (
  id uuid primary key default gen_random_uuid(),
  university_id uuid not null references public.universities(id) on delete cascade,
  label text not null, -- e.g. 2025/2026
  starts_on date not null,
  ends_on date not null,
  check (ends_on > starts_on),
  unique (university_id, label)
);

create table public.semesters (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.academic_sessions(id) on delete cascade,
  number smallint not null check (number between 1 and 3),
  starts_on date not null,
  ends_on date not null,
  check (ends_on > starts_on),
  unique (session_id, number)
);

create table public.courses (
  id uuid primary key default gen_random_uuid(),
  department_id uuid not null references public.departments(id) on delete cascade,
  code text not null,
  title text not null,
  description text,
  credit_units smallint not null check (credit_units between 0 and 12),
  level smallint not null check (level between 100 and 900),
  semester_number smallint check (semester_number between 1 and 3),
  created_at timestamptz not null default now(),
  unique (department_id, code)
);
create index courses_search on public.courses using gin (to_tsvector('english', code || ' ' || title));

create table public.course_prerequisites (
  course_id uuid not null references public.courses(id) on delete cascade,
  prerequisite_id uuid not null references public.courses(id) on delete cascade,
  primary key (course_id, prerequisite_id),
  check (course_id <> prerequisite_id)
);

-- ───────────── Profiles ─────────────
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username citext not null unique check (username ~ '^[a-z0-9_]{3,30}$'),
  full_name text check (char_length(full_name) <= 100),
  avatar_path text,
  bio text check (char_length(bio) <= 500),
  university_id uuid references public.universities(id),
  campus_id uuid references public.campuses(id),
  faculty_id uuid references public.faculties(id),
  department_id uuid references public.departments(id),
  programme_id uuid references public.programmes(id),
  level smallint check (level between 100 and 900),
  graduation_year smallint check (graduation_year between 2000 and 2100),
  skills text[] not null default '{}',
  interests text[] not null default '{}',
  verification verification_status not null default 'unverified',
  reputation integer not null default 0,
  profile_visibility profile_visibility not null default 'university',
  contact_visibility profile_visibility not null default 'private',
  message_permission message_permission not null default 'university',
  activity_visibility profile_visibility not null default 'university',
  is_suspended boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index profiles_university on public.profiles(university_id);
create index profiles_department on public.profiles(department_id);
create index profiles_name_trgm on public.profiles using gin ((coalesce(full_name,'') || ' ' || username) gin_trgm_ops);
create trigger profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, full_name)
  values (
    new.id,
    'user_' || substr(replace(new.id::text,'-',''), 1, 10),
    nullif(new.raw_user_meta_data->>'full_name','')
  );
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ───────────── Roles ─────────────
create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  role app_role not null,
  scope_type text check (scope_type in ('university','faculty','department','community')),
  scope_id uuid,
  granted_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  check ((scope_type is null) = (scope_id is null)),
  unique nulls not distinct (user_id, role, scope_type, scope_id)
);
create index user_roles_user on public.user_roles(user_id);

-- Security-definer helpers avoid RLS recursion and keep policies short.
create or replace function public.has_role(_role app_role, _scope_type text default null, _scope_id uuid default null)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_roles r
    where r.user_id = auth.uid()
      and (
        r.role = 'super_admin'
        or (r.role = _role and (r.scope_type is null
            or (r.scope_type = _scope_type and r.scope_id = _scope_id)))
      )
  )
$$;

create or replace function public.is_platform_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles
    where user_id = auth.uid() and role in ('super_admin','platform_admin') and scope_type is null)
$$;

create or replace function public.is_moderator() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles
    where user_id = auth.uid()
      and role in ('super_admin','platform_admin','content_moderator','marketplace_moderator'))
$$;

create or replace function public.my_university_id() returns uuid
language sql stable security definer set search_path = public as $$
  select university_id from public.profiles where id = auth.uid()
$$;

-- ───────────── Blocks ─────────────
create table public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index user_blocks_blocked on public.user_blocks(blocked_id);

create or replace function public.is_blocked_between(_a uuid, _b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_blocks
    where (blocker_id = _a and blocked_id = _b) or (blocker_id = _b and blocked_id = _a))
$$;

-- ───────────── Reports ─────────────
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type report_target not null,
  target_id uuid not null,
  reason text not null check (char_length(reason) between 3 and 100),
  details text check (char_length(details) <= 2000),
  status report_status not null default 'open',
  resolved_by uuid references public.profiles(id),
  resolution_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (reporter_id, target_type, target_id)
);
create index reports_queue on public.reports(status, created_at);
create trigger reports_updated before update on public.reports
  for each row execute function public.set_updated_at();

-- ───────────── Audit logs ─────────────
create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity text not null,
  entity_id text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index audit_logs_entity on public.audit_logs(entity, entity_id);
create index audit_logs_actor on public.audit_logs(actor_id, created_at desc);

create or replace function public.log_audit(_action text, _entity text, _entity_id text, _metadata jsonb default '{}')
returns void language sql security definer set search_path = public as $$
  insert into public.audit_logs(actor_id, action, entity, entity_id, metadata)
  values (auth.uid(), _action, _entity, _entity_id, coalesce(_metadata,'{}'))
$$;

-- Audit every role grant/revoke automatically.
create or replace function public.audit_role_change() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.audit_logs(actor_id, action, entity, entity_id, metadata)
  values (auth.uid(), tg_op, 'user_roles', coalesce(new.id, old.id)::text,
          to_jsonb(coalesce(new, old)));
  return coalesce(new, old);
end $$;
create trigger user_roles_audit after insert or delete on public.user_roles
  for each row execute function public.audit_role_change();

-- ───────────── Row Level Security ─────────────
alter table public.countries enable row level security;
alter table public.universities enable row level security;
alter table public.campuses enable row level security;
alter table public.faculties enable row level security;
alter table public.departments enable row level security;
alter table public.grading_schemes enable row level security;
alter table public.programmes enable row level security;
alter table public.academic_sessions enable row level security;
alter table public.semesters enable row level security;
alter table public.courses enable row level security;
alter table public.course_prerequisites enable row level security;
alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.user_blocks enable row level security;
alter table public.reports enable row level security;
alter table public.audit_logs enable row level security;

-- Reference data: readable by anyone signed in (needed at registration), written by platform admins.
do $$
declare t text;
begin
  foreach t in array array['countries','universities','campuses','faculties','departments',
    'grading_schemes','programmes','academic_sessions','semesters','courses','course_prerequisites']
  loop
    execute format('create policy %I on public.%I for select to authenticated using (true)', t || '_read', t);
    execute format('create policy %I on public.%I for all to authenticated using (public.is_platform_admin()) with check (public.is_platform_admin())', t || '_admin_write', t);
  end loop;
end $$;

-- University admins may manage their own university's structure rows.
create policy faculties_uni_admin on public.faculties for all to authenticated
  using (public.has_role('university_admin','university',university_id))
  with check (public.has_role('university_admin','university',university_id));

-- Profiles
create policy profiles_read on public.profiles for select to authenticated using (
  id = auth.uid()
  or public.is_platform_admin()
  or (
    not public.is_blocked_between(auth.uid(), id)
    and (
      profile_visibility = 'public'
      or (profile_visibility = 'university' and university_id is not null
          and university_id = public.my_university_id())
    )
  )
);
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_admin_update on public.profiles for update to authenticated
  using (public.is_platform_admin()) with check (public.is_platform_admin());

-- Column-level guard: users can never edit verification, reputation or suspension themselves.
revoke update on public.profiles from authenticated;
grant update (username, full_name, avatar_path, bio, university_id, campus_id, faculty_id,
  department_id, programme_id, level, graduation_year, skills, interests,
  profile_visibility, contact_visibility, message_permission, activity_visibility)
  on public.profiles to authenticated;
-- Admin edits of guarded columns go through a service-role Edge Function that also calls log_audit().

-- Roles: users see their own; only platform admins grant/revoke.
create policy user_roles_read on public.user_roles for select to authenticated
  using (user_id = auth.uid() or public.is_platform_admin());
create policy user_roles_admin_write on public.user_roles for all to authenticated
  using (public.is_platform_admin()) with check (public.is_platform_admin());

-- Blocks: fully private to the blocker.
create policy user_blocks_own on public.user_blocks for all to authenticated
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

-- Reports: create and read your own; moderators read and resolve all.
create policy reports_insert on public.reports for insert to authenticated
  with check (reporter_id = auth.uid() and status = 'open');
create policy reports_read on public.reports for select to authenticated
  using (reporter_id = auth.uid() or public.is_moderator());
create policy reports_moderate on public.reports for update to authenticated
  using (public.is_moderator()) with check (public.is_moderator());

-- Audit logs: platform admins read; writes only via log_audit() / triggers (no insert policy).
create policy audit_logs_read on public.audit_logs for select to authenticated
  using (public.is_platform_admin());
revoke insert, update, delete on public.audit_logs from authenticated, anon;
