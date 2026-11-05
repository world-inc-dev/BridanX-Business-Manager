drop policy if exists school_teachers_teacher_self_select on public.school_teachers;
create policy school_teachers_teacher_self_select on public.school_teachers
 for select to authenticated using (exists(
  select 1 from public.school_teacher_accounts a
  where a.user_id=school_teachers.user_id
   and a.teacher_id=school_teachers.id
   and a.auth_user_id=(select auth.uid())
   and a.account_status='active'
 ));