-- 0002_profile_integrity.sql
-- Onboarding marker, array limits, and academic-chain consistency on profiles.

alter table public.profiles add column onboarded_at timestamptz;
alter table public.profiles add constraint profiles_skills_limit
  check (cardinality(skills) <= 30);
alter table public.profiles add constraint profiles_interests_limit
  check (cardinality(interests) <= 30);

grant update (onboarded_at) on public.profiles to authenticated;

-- Reject profiles whose programme/department/faculty/university/campus do not belong together.
create or replace function public.validate_profile_academics() returns trigger
language plpgsql set search_path = public as $$
declare v_dept uuid; v_fac uuid; v_uni uuid;
begin
  if new.programme_id is not null then
    select department_id into v_dept from public.programmes where id = new.programme_id;
    if new.department_id is distinct from v_dept then
      raise exception 'programme does not belong to department' using errcode = '23514';
    end if;
  end if;
  if new.department_id is not null then
    select faculty_id into v_fac from public.departments where id = new.department_id;
    if new.faculty_id is distinct from v_fac then
      raise exception 'department does not belong to faculty' using errcode = '23514';
    end if;
  end if;
  if new.faculty_id is not null then
    select university_id into v_uni from public.faculties where id = new.faculty_id;
    if new.university_id is distinct from v_uni then
      raise exception 'faculty does not belong to university' using errcode = '23514';
    end if;
  end if;
  if new.campus_id is not null and not exists (
    select 1 from public.campuses where id = new.campus_id and university_id = new.university_id
  ) then
    raise exception 'campus does not belong to university' using errcode = '23514';
  end if;
  return new;
end $$;

create trigger profiles_validate_academics
  before insert or update on public.profiles
  for each row execute function public.validate_profile_academics();
