-- IronLog Supabase Schema
-- Run this in your Supabase project: Dashboard > SQL Editor > New query

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────────
-- Profiles (auto-created on auth.users insert)
-- ─────────────────────────────────────────────
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  username    text not null default 'Athlete',
  weight_unit text not null default 'kg',
  created_at  timestamptz not null default now()
);

-- Auto-create profile when user signs up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─────────────────────────────────────────────
-- Workout Sessions
-- ─────────────────────────────────────────────
create table if not exists public.workout_sessions (
  id         uuid primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  title      text not null default '',
  start_date timestamptz not null,
  end_date   timestamptz,
  notes      text not null default '',
  updated_at timestamptz not null default now()
);

create index if not exists workout_sessions_user_id on public.workout_sessions(user_id);
create index if not exists workout_sessions_start_date on public.workout_sessions(start_date desc);

-- ─────────────────────────────────────────────
-- Exercise Logs
-- ─────────────────────────────────────────────
create table if not exists public.exercise_logs (
  id                     uuid primary key,
  session_id             uuid not null references public.workout_sessions(id) on delete cascade,
  exercise_name          text not null,
  exercise_muscle_group  text not null default '',
  order_index            int  not null default 0
);

create index if not exists exercise_logs_session_id on public.exercise_logs(session_id);

-- ─────────────────────────────────────────────
-- Workout Sets
-- ─────────────────────────────────────────────
create table if not exists public.workout_sets (
  id           uuid primary key,
  log_id       uuid not null references public.exercise_logs(id) on delete cascade,
  order_index  int     not null default 0,
  weight       numeric not null default 0,
  reps         int     not null default 0,
  is_completed boolean not null default false
);

create index if not exists workout_sets_log_id on public.workout_sets(log_id);

-- ─────────────────────────────────────────────
-- Routines
-- ─────────────────────────────────────────────
create table if not exists public.routines (
  id         uuid primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  name       text not null,
  notes      text not null default '',
  updated_at timestamptz not null default now()
);

create index if not exists routines_user_id on public.routines(user_id);

-- ─────────────────────────────────────────────
-- Routine Exercises
-- ─────────────────────────────────────────────
create table if not exists public.routine_exercises (
  id                     uuid primary key,
  routine_id             uuid not null references public.routines(id) on delete cascade,
  exercise_name          text not null,
  exercise_muscle_group  text not null default '',
  order_index            int  not null default 0,
  target_sets            int  not null default 3,
  target_reps            int  not null default 10,
  target_weight          numeric not null default 0
);

-- ─────────────────────────────────────────────
-- Row Level Security (RLS)
-- Users can only read/write their own data
-- ─────────────────────────────────────────────
alter table public.profiles           enable row level security;
alter table public.workout_sessions   enable row level security;
alter table public.exercise_logs      enable row level security;
alter table public.workout_sets       enable row level security;
alter table public.routines           enable row level security;
alter table public.routine_exercises  enable row level security;

-- Profiles
create policy "Users can view own profile"   on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

-- Workout sessions
create policy "Users manage own sessions" on public.workout_sessions
  for all using (auth.uid() = user_id);

-- Exercise logs — accessible if session belongs to user
create policy "Users manage own logs" on public.exercise_logs
  for all using (
    exists (
      select 1 from public.workout_sessions s
      where s.id = exercise_logs.session_id and s.user_id = auth.uid()
    )
  );

-- Workout sets — accessible if log belongs to user
create policy "Users manage own sets" on public.workout_sets
  for all using (
    exists (
      select 1 from public.exercise_logs l
      join public.workout_sessions s on s.id = l.session_id
      where l.id = workout_sets.log_id and s.user_id = auth.uid()
    )
  );

-- Routines
create policy "Users manage own routines" on public.routines
  for all using (auth.uid() = user_id);

-- Routine exercises
create policy "Users manage own routine exercises" on public.routine_exercises
  for all using (
    exists (
      select 1 from public.routines r
      where r.id = routine_exercises.routine_id and r.user_id = auth.uid()
    )
  );
