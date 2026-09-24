-- 0003_academics_planner.sql
-- Course enrollments/results, weekly timetable, planner items. All rows private to their owner.

create type public.planner_kind as enum ('assignment','test','exam','study','event','task');

create table public.enrollments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  session_label text not null check (session_label ~ '^[0-9]{4}/[0-9]{4}$'),
  semester_number smallint not null check (semester_number between 1 and 3),
  score numeric(5,2) check (score between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, course_id, session_label, semester_number)
);
create index enrollments_user on public.enrollments(user_id, session_label, semester_number);
create trigger enrollments_updated before update on public.enrollments
  for each row execute function public.set_updated_at();

create table public.timetable_slots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  weekday smallint not null check (weekday between 1 and 7),
  starts_at time not null,
  ends_at time not null,
  venue text check (char_length(venue) <= 120),
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);
create index timetable_user on public.timetable_slots(user_id, weekday, starts_at);

create table public.planner_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  kind planner_kind not null,
  title text not null check (char_length(title) between 1 and 120),
  due_at timestamptz not null,
  location text check (char_length(location) <= 120),
  notes text check (char_length(notes) <= 1000),
  is_done boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index planner_user_due on public.planner_items(user_id, due_at);
create trigger planner_updated before update on public.planner_items
  for each row execute function public.set_updated_at();

alter table public.enrollments enable row level security;
alter table public.timetable_slots enable row level security;
alter table public.planner_items enable row level security;

create policy enrollments_own on public.enrollments for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy timetable_own on public.timetable_slots for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy planner_own on public.planner_items for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
