-- BridanX Business Manager: secure multi-user database
-- Run this in the Supabase SQL Editor for the dedicated Business Manager project.
-- Supabase Auth manages passwords; never store passwords in these tables.

create extension if not exists pgcrypto;

create table if not exists public.business_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  business_name text not null default 'My Business',
  country_code text not null default 'NG',
  currency_code text not null default 'NGN',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  description text not null,
  category text not null default 'Other',
  type text not null check (type in ('Income','Expense')),
  amount numeric(14,2) not null check (amount > 0),
  transaction_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  item text not null,
  customer text,
  amount numeric(14,2) not null check (amount > 0),
  payment_method text not null default 'Other',
  sale_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.inventory (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  sku text,
  quantity numeric(14,2) not null default 0 check (quantity >= 0),
  unit_price numeric(14,2) not null default 0 check (unit_price >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  phone text,
  email text,
  created_at timestamptz not null default now()
);

create index if not exists transactions_user_date_idx on public.transactions(user_id, transaction_date desc);
create index if not exists sales_user_date_idx on public.sales(user_id, sale_date desc);
create index if not exists inventory_user_idx on public.inventory(user_id);
create index if not exists customers_user_idx on public.customers(user_id);

alter table public.business_profiles enable row level security;
alter table public.transactions enable row level security;
alter table public.sales enable row level security;
alter table public.inventory enable row level security;
alter table public.customers enable row level security;

drop policy if exists "Users manage their own business profile" on public.business_profiles;
create policy "Users manage their own business profile" on public.business_profiles
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Users manage their own transactions" on public.transactions;
create policy "Users manage their own transactions" on public.transactions
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Users manage their own sales" on public.sales;
create policy "Users manage their own sales" on public.sales
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Users manage their own inventory" on public.inventory;
create policy "Users manage their own inventory" on public.inventory
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Users manage their own customers" on public.customers;
create policy "Users manage their own customers" on public.customers
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.business_profiles, public.transactions, public.sales, public.inventory, public.customers to authenticated;
