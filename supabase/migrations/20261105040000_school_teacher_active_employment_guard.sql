create or replace function private.school_teacher_can_access_class(p_owner uuid,p_class uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select exists(select 1 from public.school_teacher_accounts a
 join public.school_teachers t on t.user_id=a.user_id and t.id=a.teacher_id and t.employment_status='active'
 join public.school_class_subjects cs on cs.user_id=a.user_id and cs.teacher_id=a.teacher_id
 where a.user_id=p_owner and a.auth_user_id=(select auth.uid()) and a.account_status='active' and cs.class_id=p_class);
$$;

create or replace function private.school_teacher_can_access_subject(p_owner uuid,p_class uuid,p_subject text,p_year text)
returns boolean language sql stable security definer set search_path=''
as $$
 select exists(select 1 from public.school_teacher_accounts a
 join public.school_teachers t on t.user_id=a.user_id and t.id=a.teacher_id and t.employment_status='active'
 join public.school_class_subjects cs on cs.user_id=a.user_id and cs.teacher_id=a.teacher_id
 join public.school_subjects s on s.user_id=cs.user_id and s.id=cs.subject_id
 where a.user_id=p_owner and a.auth_user_id=(select auth.uid()) and a.account_status='active'
 and cs.class_id=p_class and cs.academic_year=p_year and lower(s.subject_name)=lower(p_subject));
$$;

drop policy if exists school_subjects_teacher_select on public.school_subjects;
create policy school_subjects_teacher_select on public.school_subjects for select to authenticated
using (exists(select 1 from public.school_teacher_accounts a
 join public.school_teachers t on t.user_id=a.user_id and t.id=a.teacher_id and t.employment_status='active'
 join public.school_class_subjects cs on cs.user_id=a.user_id and cs.teacher_id=a.teacher_id
 where a.user_id=school_subjects.user_id and a.auth_user_id=(select auth.uid())
 and a.account_status='active' and cs.subject_id=school_subjects.id));

drop policy if exists school_class_subjects_teacher_select on public.school_class_subjects;
create policy school_class_subjects_teacher_select on public.school_class_subjects for select to authenticated
using (exists(select 1 from public.school_teacher_accounts a
 join public.school_teachers t on t.user_id=a.user_id and t.id=a.teacher_id and t.employment_status='active'
 where a.user_id=school_class_subjects.user_id and a.teacher_id=school_class_subjects.teacher_id
 and a.auth_user_id=(select auth.uid()) and a.account_status='active'));

drop policy if exists school_exams_teacher_select on public.school_exams;
create policy school_exams_teacher_select on public.school_exams for select to authenticated
using (exists(select 1 from public.school_teacher_accounts a
 join public.school_teachers t on t.user_id=a.user_id and t.id=a.teacher_id and t.employment_status='active'
 join public.school_class_subjects cs on cs.user_id=a.user_id and cs.teacher_id=a.teacher_id
 where a.user_id=school_exams.user_id and a.auth_user_id=(select auth.uid())
 and a.account_status='active' and cs.academic_year=school_exams.academic_year));

create index if not exists school_teacher_invites_owner_teacher_claimed_idx
 on public.school_teacher_invites(user_id,teacher_id,claimed_at);