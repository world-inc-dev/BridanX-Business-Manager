create table if not exists public.school_teachers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  staff_no text not null,
  full_name text not null,
  phone text,
  email text,
  employment_status text not null default 'active' check (employment_status in ('active','inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, staff_no),
  unique(user_id, id)
);

create table if not exists public.school_subjects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject_name text not null,
  subject_code text,
  created_at timestamptz not null default now(),
  unique(user_id, subject_name),
  unique(user_id, id)
);

create table if not exists public.school_class_subjects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  class_id uuid not null,
  subject_id uuid not null,
  teacher_id uuid,
  academic_year text not null,
  created_at timestamptz not null default now(),
  constraint school_class_subjects_class_owner_fk
    foreign key(user_id, class_id) references public.school_classes(user_id, id) on delete cascade,
  constraint school_class_subjects_subject_owner_fk
    foreign key(user_id, subject_id) references public.school_subjects(user_id, id) on delete cascade,
  constraint school_class_subjects_teacher_owner_fk
    foreign key(user_id, teacher_id) references public.school_teachers(user_id, id) on delete set null (teacher_id),
  unique(user_id, class_id, subject_id, academic_year)
);

create index if not exists school_teachers_user_status_idx on public.school_teachers(user_id, employment_status);
create index if not exists school_subjects_user_name_idx on public.school_subjects(user_id, subject_name);
create index if not exists school_class_subjects_user_class_idx on public.school_class_subjects(user_id, class_id, academic_year);

alter table public.school_teachers enable row level security;
alter table public.school_subjects enable row level security;
alter table public.school_class_subjects enable row level security;

grant select, insert, update, delete on public.school_teachers to authenticated;
grant select, insert, update, delete on public.school_subjects to authenticated;
grant select, insert, update, delete on public.school_class_subjects to authenticated;

create policy school_teachers_owner_all on public.school_teachers
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy school_subjects_owner_all on public.school_subjects
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy school_class_subjects_owner_all on public.school_class_subjects
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
