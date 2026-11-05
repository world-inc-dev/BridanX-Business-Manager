create or replace function public.school_teacher_can_access_class(p_owner uuid,p_class uuid)
returns boolean language sql stable security definer set search_path=public
as $$
 select exists(
  select 1 from public.school_teacher_accounts a
  join public.school_class_subjects cs on cs.user_id=a.user_id and cs.teacher_id=a.teacher_id
  where a.user_id=p_owner and a.auth_user_id=(select auth.uid()) and a.account_status='active'
    and cs.class_id=p_class
 );
$$;
create or replace function public.school_teacher_can_access_subject(p_owner uuid,p_class uuid,p_subject text,p_year text)
returns boolean language sql stable security definer set search_path=public
as $$
 select exists(
  select 1 from public.school_teacher_accounts a
  join public.school_class_subjects cs on cs.user_id=a.user_id and cs.teacher_id=a.teacher_id
  join public.school_subjects s on s.user_id=cs.user_id and s.id=cs.subject_id
  where a.user_id=p_owner and a.auth_user_id=(select auth.uid()) and a.account_status='active'
    and cs.class_id=p_class and cs.academic_year=p_year
    and lower(s.subject_name)=lower(p_subject)
 );
$$;
grant execute on function public.school_teacher_can_access_class(uuid,uuid) to authenticated;
grant execute on function public.school_teacher_can_access_subject(uuid,uuid,text,text) to authenticated;
create policy school_classes_teacher_select on public.school_classes
 for select to authenticated using (public.school_teacher_can_access_class(user_id,id));
create policy school_students_teacher_select on public.school_students
 for select to authenticated using (public.school_teacher_can_access_class(user_id,class_id));
create policy school_subjects_teacher_select on public.school_subjects
 for select to authenticated using (exists(
  select 1 from public.school_teacher_accounts a
  join public.school_class_subjects cs on cs.user_id=a.user_id and cs.teacher_id=a.teacher_id
  where a.user_id=school_subjects.user_id and a.auth_user_id=(select auth.uid())
   and a.account_status='active' and cs.subject_id=school_subjects.id
 ));
create policy school_class_subjects_teacher_select on public.school_class_subjects
 for select to authenticated using (exists(
  select 1 from public.school_teacher_accounts a where a.user_id=school_class_subjects.user_id
   and a.teacher_id=school_class_subjects.teacher_id and a.auth_user_id=(select auth.uid()) and a.account_status='active'
 ));
create policy school_exams_teacher_select on public.school_exams
 for select to authenticated using (exists(
  select 1 from public.school_teacher_accounts a
  join public.school_class_subjects cs on cs.user_id=a.user_id and cs.teacher_id=a.teacher_id
  where a.user_id=school_exams.user_id and a.auth_user_id=(select auth.uid())
   and a.account_status='active' and cs.academic_year=school_exams.academic_year
 ));
create policy school_attendance_teacher_select on public.school_student_attendance
 for select to authenticated using (exists(
  select 1 from public.school_students s where s.user_id=school_student_attendance.user_id
   and s.id=school_student_attendance.student_id
   and public.school_teacher_can_access_class(s.user_id,s.class_id)
 ));
create policy school_attendance_teacher_insert on public.school_student_attendance
 for insert to authenticated with check (exists(
  select 1 from public.school_students s where s.user_id=school_student_attendance.user_id
   and s.id=school_student_attendance.student_id
   and public.school_teacher_can_access_class(s.user_id,s.class_id)
 ));
create policy school_attendance_teacher_update on public.school_student_attendance
 for update to authenticated using (exists(
  select 1 from public.school_students s where s.user_id=school_student_attendance.user_id
   and s.id=school_student_attendance.student_id
   and public.school_teacher_can_access_class(s.user_id,s.class_id)
 )) with check (exists(
  select 1 from public.school_students s where s.user_id=school_student_attendance.user_id
   and s.id=school_student_attendance.student_id
   and public.school_teacher_can_access_class(s.user_id,s.class_id)
 ));
create policy school_results_teacher_select on public.school_exam_results
 for select to authenticated using (exists(
  select 1 from public.school_students s join public.school_exams e on e.id=school_exam_results.exam_id and e.user_id=school_exam_results.user_id
  where s.user_id=school_exam_results.user_id and s.id=school_exam_results.student_id
   and public.school_teacher_can_access_subject(s.user_id,s.class_id,school_exam_results.subject,e.academic_year)
 ));
create policy school_results_teacher_insert on public.school_exam_results
 for insert to authenticated with check (exists(
  select 1 from public.school_students s join public.school_exams e on e.id=school_exam_results.exam_id and e.user_id=school_exam_results.user_id
  where s.user_id=school_exam_results.user_id and s.id=school_exam_results.student_id
   and public.school_teacher_can_access_subject(s.user_id,s.class_id,school_exam_results.subject,e.academic_year)
 ));
create policy school_results_teacher_update on public.school_exam_results
 for update to authenticated using (exists(
  select 1 from public.school_students s join public.school_exams e on e.id=school_exam_results.exam_id and e.user_id=school_exam_results.user_id
  where s.user_id=school_exam_results.user_id and s.id=school_exam_results.student_id
   and public.school_teacher_can_access_subject(s.user_id,s.class_id,school_exam_results.subject,e.academic_year)
 )) with check (exists(
  select 1 from public.school_students s join public.school_exams e on e.id=school_exam_results.exam_id and e.user_id=school_exam_results.user_id
  where s.user_id=school_exam_results.user_id and s.id=school_exam_results.student_id
   and public.school_teacher_can_access_subject(s.user_id,s.class_id,school_exam_results.subject,e.academic_year)
 ));
