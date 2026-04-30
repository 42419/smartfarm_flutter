-- Keep only the most recent 30 days of sensor history.
delete from public.sensor_readings
where recorded_at < now() - interval '30 days';

-- Optional: run this to see how many rows remain.
select count(*) as remaining_rows
from public.sensor_readings;
