-- Add a JSON column to store per-language data under a single field.
-- This avoids creating numeric columns like "1", "2", etc.
--
-- Run in Supabase SQL Editor.

alter table public."user"
  add column if not exists langs jsonb not null default '{}'::jsonb;

-- Optional but recommended (if you don't already have these):
alter table public."user"
  add column if not exists count_lang integer not null default 0;

-- If your app also uses these and they don't exist yet:
-- alter table public."user" add column if not exists leader_board integer not null default 0;
-- alter table public."user" add column if not exists avtar_url text not null default '';
-- alter table public."user" add column if not exists status boolean not null default false;
