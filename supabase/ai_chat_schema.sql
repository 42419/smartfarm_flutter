-- AI 对话历史表
-- RLS 策略见 auth_migration.sql（使用 auth.uid() 隔离）
create table if not exists public.ai_conversations (
  id uuid primary key,
  user_id text not null,
  auth_user_id uuid references auth.users(id),
  title text not null default '新对话',
  coze_conversation_id text,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now())
);

create table if not exists public.ai_messages (
  id bigint generated always as identity primary key,
  conversation_id uuid not null references public.ai_conversations(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz not null default timezone('utc'::text, now())
);

create index if not exists ai_conversations_user_id_updated_at_idx
  on public.ai_conversations (auth_user_id, updated_at desc);

create index if not exists ai_messages_conversation_id_created_at_idx
  on public.ai_messages (conversation_id, created_at);

alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
