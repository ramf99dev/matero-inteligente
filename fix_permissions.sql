-- FIX RLS POLICIES
-- Run this to clear old policies and set up the correct ones for both Anon and Authenticated users.

-- 1. Drop existing policies to avoid "already exists" errors
drop policy if exists "Allow anonymous inserts" on public.matero_readings;
drop policy if exists "Allow anonymous select" on public.matero_readings;
drop policy if exists "Allow authenticated inserts" on public.matero_readings;
drop policy if exists "Allow authenticated select" on public.matero_readings;

-- 2. Re-create policies
-- Anon policies
create policy "Allow anonymous inserts"
  on public.matero_readings for insert to anon with check (true);

create policy "Allow anonymous select"
  on public.matero_readings for select to anon using (true);

-- Authenticated policies
create policy "Allow authenticated inserts"
  on public.matero_readings for insert to authenticated with check (true);

create policy "Allow authenticated select"
  on public.matero_readings for select to authenticated using (true);

-- 3. Verify Profiles setup (Safe to run again)
-- Ensure the table exists
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade not null primary key,
  email text,
  username text,
  avatar_url text,
  updated_at timestamptz
);

alter table public.profiles enable row level security;

-- Drop profile policies to refresh them
drop policy if exists "Public profiles are viewable by everyone." on profiles;
drop policy if exists "Users can insert their own profile." on profiles;
drop policy if exists "Users can update their own profile." on profiles;

create policy "Public profiles are viewable by everyone."
  on profiles for select using (true);

create policy "Users can insert their own profile."
  on profiles for insert with check (auth.uid() = id);

create policy "Users can update their own profile."
  on profiles for update using (auth.uid() = id);
