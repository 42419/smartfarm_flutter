create table if not exists public.app_users (
  username text primary key,
  password text not null,
  nickname text not null default '',
  avatar_url text,
  bio text,
  email text,
  phone text,
  profession text,
  farm text not null default ''
);

alter table public.app_users add column if not exists avatar_url text;
alter table public.app_users add column if not exists bio text;

create table if not exists public.crops (
  crop_name text primary key,
  plant_date date not null,
  harvest_date date not null,
  area double precision not null default 0,
  current integer not null default 0,
  total integer not null default 0,
  height text not null default '',
  leaf_count text not null default '',
  health text not null default '',
  yield_text text not null default '',
  environment_analysis_1 integer not null default 0,
  environment_analysis_2 integer not null default 0,
  environment_analysis_3 integer not null default 0,
  environment_analysis_4 integer not null default 0,
  environment_analysis_5 integer not null default 0,
  desc_1 text not null default '',
  recommendation_1 text not null default '',
  desc_2 text not null default '',
  recommendation_2 text not null default '',
  crop_img text not null default '',
  task_time_1 text not null default '',
  task_time_2 text not null default ''
);

create unique index if not exists sensor_readings_greenhouse_recorded_at_uidx
  on public.sensor_readings (greenhouse, recorded_at);

alter table public.app_users enable row level security;
alter table public.crops enable row level security;

create policy "anon_can_read_app_users"
  on public.app_users
  for select
  to anon
  using (true);

create policy "anon_can_insert_app_users"
  on public.app_users
  for insert
  to anon
  with check (true);

create policy "anon_can_update_app_users"
  on public.app_users
  for update
  to anon
  using (true)
  with check (true);

create policy "anon_can_read_crops"
  on public.crops
  for select
  to anon
  using (true);

create policy "anon_can_insert_crops"
  on public.crops
  for insert
  to anon
  with check (true);

create policy "anon_can_update_crops"
  on public.crops
  for update
  to anon
  using (true)
  with check (true);
