-- ====================================================
-- Supabase Auth 迁移脚本（可重复执行）
-- 用途：从自定义 app_users 迁移到 Supabase Auth
-- ====================================================

-- 1. 创建 profiles 表（存储用户额外信息）
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  email text,
  nickname text not null default '',
  avatar_url text,
  bio text,
  phone text,
  profession text,
  farm text not null default '',
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now())
);

alter table public.profiles enable row level security;

alter table public.profiles add column if not exists email text;

drop policy if exists "users_can_read_own_profile" on public.profiles;
create policy "users_can_read_own_profile"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "users_can_update_own_profile" on public.profiles;
create policy "users_can_update_own_profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "users_can_insert_own_profile" on public.profiles;
create policy "users_can_insert_own_profile"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

-- 2. 触发器：Supabase Auth 注册时自动创建 profile
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, email, nickname)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', new.email),
    new.email,
    coalesce(new.raw_user_meta_data ->> 'nickname', '')
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ====================================================
-- 3. 更新 AI 对话表的 RLS 策略
-- ====================================================

alter table public.ai_conversations
  add column if not exists auth_user_id uuid references auth.users(id);

-- 删除可能存在的旧策略
do $$
begin
  if exists (select 1 from pg_policies where policyname = 'anon_can_select_ai_conversations') then
    drop policy "anon_can_select_ai_conversations" on public.ai_conversations;
  end if;
  if exists (select 1 from pg_policies where policyname = 'anon_can_insert_ai_conversations') then
    drop policy "anon_can_insert_ai_conversations" on public.ai_conversations;
  end if;
  if exists (select 1 from pg_policies where policyname = 'anon_can_update_ai_conversations') then
    drop policy "anon_can_update_ai_conversations" on public.ai_conversations;
  end if;
  if exists (select 1 from pg_policies where policyname = 'anon_can_delete_ai_conversations') then
    drop policy "anon_can_delete_ai_conversations" on public.ai_conversations;
  end if;
  if exists (select 1 from pg_policies where policyname = 'anon_can_select_ai_messages') then
    drop policy "anon_can_select_ai_messages" on public.ai_messages;
  end if;
  if exists (select 1 from pg_policies where policyname = 'anon_can_insert_ai_messages') then
    drop policy "anon_can_insert_ai_messages" on public.ai_messages;
  end if;
  if exists (select 1 from pg_policies where policyname = 'anon_can_delete_ai_messages') then
    drop policy "anon_can_delete_ai_messages" on public.ai_messages;
  end if;
end;
$$;

drop policy if exists "users_can_select_own_conversations" on public.ai_conversations;
drop policy if exists "users_can_insert_own_conversations" on public.ai_conversations;
drop policy if exists "users_can_update_own_conversations" on public.ai_conversations;
drop policy if exists "users_can_delete_own_conversations" on public.ai_conversations;
drop policy if exists "users_can_select_own_messages" on public.ai_messages;
drop policy if exists "users_can_insert_own_messages" on public.ai_messages;
drop policy if exists "users_can_delete_own_messages" on public.ai_messages;

create policy "users_can_select_own_conversations"
  on public.ai_conversations for select
  to authenticated
  using (auth_user_id = auth.uid());

create policy "users_can_insert_own_conversations"
  on public.ai_conversations for insert
  to authenticated
  with check (auth_user_id = auth.uid());

create policy "users_can_update_own_conversations"
  on public.ai_conversations for update
  to authenticated
  using (auth_user_id = auth.uid())
  with check (auth_user_id = auth.uid());

create policy "users_can_delete_own_conversations"
  on public.ai_conversations for delete
  to authenticated
  using (auth_user_id = auth.uid());

create policy "users_can_select_own_messages"
  on public.ai_messages for select
  to authenticated
  using (
    conversation_id in (
      select id from public.ai_conversations where auth_user_id = auth.uid()
    )
  );

create policy "users_can_insert_own_messages"
  on public.ai_messages for insert
  to authenticated
  with check (
    conversation_id in (
      select id from public.ai_conversations where auth_user_id = auth.uid()
    )
  );

create policy "users_can_delete_own_messages"
  on public.ai_messages for delete
  to authenticated
  using (
    conversation_id in (
      select id from public.ai_conversations where auth_user_id = auth.uid()
    )
  );

-- ====================================================
-- 4. 辅助函数
-- ====================================================

create or replace function public.lookup_email_by_username(p_username text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text;
begin
  select au.email into v_email
  from public.profiles p
  join auth.users au on au.id = p.id
  where p.username = p_username;
  return v_email;
end;
$$;

create or replace function public.get_user_id_by_email(p_email text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  select id into v_id from auth.users where email = p_email;
  return v_id;
end;
$$;

-- ====================================================
-- 5. 补全旧表的 authenticated 角色权限
--    迁移到 Supabase Auth 后请求以 authenticated 角色执行
--    原有策略只对 anon 开放，导致登录后查不到数据
-- ====================================================

-- sensor_readings
drop policy if exists "authenticated_read_sensor_readings" on public.sensor_readings;
create policy "authenticated_read_sensor_readings" on public.sensor_readings for select to authenticated using (true);
drop policy if exists "authenticated_insert_sensor_readings" on public.sensor_readings;
create policy "authenticated_insert_sensor_readings" on public.sensor_readings for insert to authenticated with check (true);

-- crops
drop policy if exists "authenticated_read_crops" on public.crops;
create policy "authenticated_read_crops" on public.crops for select to authenticated using (true);
drop policy if exists "authenticated_insert_crops" on public.crops;
create policy "authenticated_insert_crops" on public.crops for insert to authenticated with check (true);
drop policy if exists "authenticated_update_crops" on public.crops;
create policy "authenticated_update_crops" on public.crops for update to authenticated using (true) with check (true);

-- app_users（如果仍在使用）
drop policy if exists "authenticated_read_app_users" on public.app_users;
create policy "authenticated_read_app_users" on public.app_users for select to authenticated using (true);
drop policy if exists "authenticated_insert_app_users" on public.app_users;
create policy "authenticated_insert_app_users" on public.app_users for insert to authenticated with check (true);
drop policy if exists "authenticated_update_app_users" on public.app_users;
create policy "authenticated_update_app_users" on public.app_users for update to authenticated using (true) with check (true);
