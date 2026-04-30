create table if not exists public.sensor_readings (
  id bigint generated always as identity primary key,
  greenhouse text not null,
  temperature double precision,
  humidity double precision,
  illumination double precision,
  soil_moisture double precision,
  co2 double precision,
  ph_value double precision,
  recorded_at timestamptz not null default timezone('utc'::text, now())
);

create index if not exists sensor_readings_greenhouse_recorded_at_idx
  on public.sensor_readings (greenhouse, recorded_at desc);

alter table public.sensor_readings enable row level security;

create policy "anon_can_read_sensor_readings"
  on public.sensor_readings
  for select
  to anon
  using (true);

create policy "anon_can_insert_sensor_readings"
  on public.sensor_readings
  for insert
  to anon
  with check (true);
