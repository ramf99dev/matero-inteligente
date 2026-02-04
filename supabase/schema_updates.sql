-- Create devices table
create table if not exists public.devices (
  id text primary key, -- e.g. "GOTA-7429"
  user_id uuid references auth.users not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for devices
alter table public.devices enable row level security;

-- Policies for devices
drop policy if exists "Users can view their own devices" on public.devices;
create policy "Users can view their own devices" on public.devices
  for select using (auth.uid() = user_id);

drop policy if exists "Users can insert their own devices" on public.devices;
create policy "Users can insert their own devices" on public.devices
  for insert with check (auth.uid() = user_id);

-- Add device_id to plants table
alter table public.plants 
add column if not exists device_id text references public.devices(id);

-- Add device_id to matero_readings table
alter table public.matero_readings
add column if not exists device_id text references public.devices(id);

-- Index for faster querying by device_id
create index if not exists matero_readings_device_id_idx on public.matero_readings(device_id);
