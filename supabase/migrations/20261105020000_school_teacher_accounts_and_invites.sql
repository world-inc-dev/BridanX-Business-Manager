create table if not exists public.school_teacher_accounts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 teacher_id uuid not null,
 auth_user_id uuid references auth.users(id) on delete set null,
 account_status text not null default 'pending' check (account_status in ('pending','active','suspended')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(user_id,teacher_id),
 unique(auth_user_id),
 constraint school_teacher_accounts_teacher_owner_fk foreign key(user_id,teacher_id)
  references public.school_teachers(user_id,id) on delete cascade
);
create table if not exists public.school_teacher_invites (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 teacher_id uuid not null,
 email text not null,
 token_hash text not null unique,
 expires_at timestamptz not null,
 claimed_at timestamptz,
 created_at timestamptz not null default now(),
 constraint school_teacher_invites_teacher_owner_fk foreign key(user_id,teacher_id)
  references public.school_teachers(user_id,id) on delete cascade
);
create index if not exists school_teacher_accounts_user_teacher_idx on public.school_teacher_accounts(user_id,teacher_id);
create index if not exists school_teacher_invites_owner_expiry_idx on public.school_teacher_invites(user_id,expires_at);
alter table public.school_teacher_accounts enable row level security;
alter table public.school_teacher_invites enable row level security;
grant select,insert,update,delete on public.school_teacher_accounts to authenticated;
grant select,insert,update,delete on public.school_teacher_invites to authenticated;
create policy school_teacher_accounts_owner_manage on public.school_teacher_accounts
 for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy school_teacher_accounts_teacher_view on public.school_teacher_accounts
 for select to authenticated using ((select auth.uid())=auth_user_id);
create policy school_teacher_invites_owner_manage on public.school_teacher_invites
 for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);