-- HASAAN Academy production database schema
-- Run this in Supabase SQL Editor. Public sign-up must remain disabled.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null check (role in ('admin','teacher')) default 'teacher',
  created_at timestamptz not null default now()
);
create table if not exists public.teacher_classes (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  class_name text not null check (class_name in ('6th','7th','8th','9th','10th','11th','12th')),
  primary key (profile_id,class_name)
);
create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (length(trim(full_name)) between 1 and 140),
  class_name text not null check (class_name in ('6th','7th','8th','9th','10th','11th','12th')),
  guardian_name text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  attendance_date date not null,
  status text not null check (status in ('present','absent')),
  marked_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(student_id,attendance_date)
);
create table if not exists public.fees (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  fee_month date not null check (extract(day from fee_month)=1),
  amount_due numeric(12,2) not null default 0 check (amount_due >= 0),
  amount_paid numeric(12,2) not null default 0 check (amount_paid >= 0),
  status text not null check (status in ('paid','partial','unpaid')),
  recorded_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(student_id,fee_month),
  check (amount_paid <= amount_due)
);
create index if not exists students_class_active_idx on public.students(class_name,active);
create index if not exists attendance_date_idx on public.attendance(attendance_date);
create index if not exists fees_month_idx on public.fees(fee_month);

create or replace function public.current_staff_role()
returns text language sql stable security definer set search_path=public
as $$ select role from public.profiles where id=auth.uid() $$;
create or replace function public.can_access_class(target_class text)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
or exists(select 1 from public.teacher_classes tc where tc.profile_id=auth.uid() and tc.class_name=target_class) $$;
revoke all on function public.current_staff_role() from public;
revoke all on function public.can_access_class(text) from public;
grant execute on function public.current_staff_role() to authenticated;
grant execute on function public.can_access_class(text) to authenticated;

alter table public.profiles enable row level security;
alter table public.teacher_classes enable row level security;
alter table public.students enable row level security;
alter table public.attendance enable row level security;
alter table public.fees enable row level security;

-- Staff can read their own profile. Only an administrator can read/manage all profiles.
create policy "profile self or admin read" on public.profiles for select to authenticated
using (id=auth.uid() or public.current_staff_role()='admin');
create policy "admin manages profiles" on public.profiles for all to authenticated
using (public.current_staff_role()='admin') with check (public.current_staff_role()='admin');

create policy "teacher sees own class assignments or admin" on public.teacher_classes for select to authenticated
using (profile_id=auth.uid() or public.current_staff_role()='admin');
create policy "admin manages teacher assignments" on public.teacher_classes for all to authenticated
using (public.current_staff_role()='admin') with check (public.current_staff_role()='admin');

create policy "staff read students in assigned classes" on public.students for select to authenticated
using (public.can_access_class(class_name));
create policy "admin inserts students" on public.students for insert to authenticated
with check (public.current_staff_role()='admin');
create policy "admin updates students" on public.students for update to authenticated
using (public.current_staff_role()='admin') with check (public.current_staff_role()='admin');
create policy "admin deletes students" on public.students for delete to authenticated
using (public.current_staff_role()='admin');

create policy "staff read attendance for assigned classes" on public.attendance for select to authenticated
using (exists(select 1 from public.students s where s.id=student_id and public.can_access_class(s.class_name)));
create policy "staff record attendance for assigned classes" on public.attendance for insert to authenticated
with check (marked_by=auth.uid() and exists(select 1 from public.students s where s.id=student_id and public.can_access_class(s.class_name)));
create policy "staff update attendance for assigned classes" on public.attendance for update to authenticated
using (exists(select 1 from public.students s where s.id=student_id and public.can_access_class(s.class_name)))
with check (marked_by=auth.uid() and exists(select 1 from public.students s where s.id=student_id and public.can_access_class(s.class_name)));
create policy "admin deletes attendance" on public.attendance for delete to authenticated
using (public.current_staff_role()='admin');

-- Fee data is deliberately administrator-only. Teachers have no fee access.
create policy "admin only reads fees" on public.fees for select to authenticated
using (public.current_staff_role()='admin');
create policy "admin only inserts fees" on public.fees for insert to authenticated
with check (public.current_staff_role()='admin' and recorded_by=auth.uid());
create policy "admin only updates fees" on public.fees for update to authenticated
using (public.current_staff_role()='admin') with check (public.current_staff_role()='admin' and recorded_by=auth.uid());
create policy "admin only deletes fees" on public.fees for delete to authenticated
using (public.current_staff_role()='admin');

-- Do not create a public signup policy. Create users through Supabase Dashboard or a trusted
-- server-side Admin API, then create their profiles and teacher class assignments as below.
