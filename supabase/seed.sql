-- DEVELOPMENT SEED ONLY. Entirely fictional institutions and courses. Never run in production.
insert into public.countries (code, name) values ('NG', 'Nigeria') on conflict do nothing;

insert into public.grading_schemes (id, university_id, name, max_points, grades, is_default) values
('c0000000-0000-4000-8000-000000000001', null, 'Nigerian 5-point scale', 5.0,
 '[{"letter":"A","min":70,"points":5},{"letter":"B","min":60,"points":4},{"letter":"C","min":50,"points":3},{"letter":"D","min":45,"points":2},{"letter":"E","min":40,"points":1},{"letter":"F","min":0,"points":0}]'::jsonb,
 true)
on conflict do nothing;

insert into public.universities (id, country_code, name, short_name, slug) values
('a1000000-0000-4000-8000-000000000001', 'NG', 'Northbridge University', 'NBU', 'northbridge-university'),
('a1000000-0000-4000-8000-000000000002', 'NG', 'Riverside Institute of Technology', 'RIT', 'riverside-institute')
on conflict do nothing;

insert into public.campuses (university_id, name, city, state) values
('a1000000-0000-4000-8000-000000000001', 'Main Campus', 'Ibadan', 'Oyo'),
('a1000000-0000-4000-8000-000000000002', 'Main Campus', 'Port Harcourt', 'Rivers')
on conflict do nothing;

insert into public.faculties (id, university_id, name) values
('f1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'Faculty of Science'),
('f1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000001', 'Faculty of Engineering'),
('f1000000-0000-4000-8000-000000000003', 'a1000000-0000-4000-8000-000000000002', 'Faculty of Technology')
on conflict do nothing;

insert into public.departments (id, faculty_id, name) values
('d1000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'Computer Science'),
('d1000000-0000-4000-8000-000000000002', 'f1000000-0000-4000-8000-000000000001', 'Mathematics'),
('d1000000-0000-4000-8000-000000000003', 'f1000000-0000-4000-8000-000000000002', 'Electrical Engineering'),
('d1000000-0000-4000-8000-000000000004', 'f1000000-0000-4000-8000-000000000002', 'Civil Engineering'),
('d1000000-0000-4000-8000-000000000005', 'f1000000-0000-4000-8000-000000000003', 'Software Engineering')
on conflict do nothing;

insert into public.programmes (id, department_id, name, duration_years, grading_scheme_id) values
('e1000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'B.Sc. Computer Science', 4, 'c0000000-0000-4000-8000-000000000001'),
('e1000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000002', 'B.Sc. Mathematics', 4, 'c0000000-0000-4000-8000-000000000001'),
('e1000000-0000-4000-8000-000000000003', 'd1000000-0000-4000-8000-000000000003', 'B.Eng. Electrical Engineering', 5, 'c0000000-0000-4000-8000-000000000001'),
('e1000000-0000-4000-8000-000000000004', 'd1000000-0000-4000-8000-000000000004', 'B.Eng. Civil Engineering', 5, 'c0000000-0000-4000-8000-000000000001'),
('e1000000-0000-4000-8000-000000000005', 'd1000000-0000-4000-8000-000000000005', 'B.Tech. Software Engineering', 4, 'c0000000-0000-4000-8000-000000000001')
on conflict do nothing;

insert into public.courses (department_id, code, title, description, credit_units, level, semester_number) values
('d1000000-0000-4000-8000-000000000001', 'CSC101', 'Introduction to Computer Science', 'Foundations of computing.', 3, 100, 1),
('d1000000-0000-4000-8000-000000000001', 'CSC102', 'Introduction to Programming', 'Programming fundamentals.', 3, 100, 2),
('d1000000-0000-4000-8000-000000000001', 'CSC201', 'Data Structures', 'Lists, trees, graphs and complexity.', 3, 200, 1),
('d1000000-0000-4000-8000-000000000002', 'MTH101', 'General Mathematics I', 'Algebra and calculus basics.', 3, 100, 1)
on conflict do nothing;

insert into public.course_prerequisites (course_id, prerequisite_id)
select c.id, p.id from public.courses c, public.courses p
where c.code = 'CSC201' and p.code = 'CSC102' and c.department_id = p.department_id
on conflict do nothing;
