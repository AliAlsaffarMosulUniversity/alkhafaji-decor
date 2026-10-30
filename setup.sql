-- ديكورات محمد الخفاجي: إعداد قاعدة البيانات في Supabase
-- الصق هذا الملف كاملاً في: Supabase > SQL Editor > New query ثم اضغط Run

-- التصاميم
create table if not exists public.designs (
  id uuid primary key default gen_random_uuid(),
  num bigint generated always as identity,
  created_at timestamptz not null default now(),
  category text not null,
  title text default '',
  note text default '',
  image text not null            -- اسم الصورة داخل مخزن designs
);

-- معلومات المحل (صف واحد فقط)
create table if not exists public.settings (
  id int primary key default 1 check (id = 1),
  name text default 'ديكورات محمد الخفاجي',
  tag text default '',
  phone text default '',
  whatsapp text default '',
  address text default '',
  instagram text default ''
);
insert into public.settings (id) values (1) on conflict (id) do nothing;

-- الزبائن يقرؤون فقط، وصاحب الحساب المسجّل يضيف ويعدّل ويحذف
alter table public.designs enable row level security;
alter table public.settings enable row level security;

drop policy if exists "public read designs" on public.designs;
create policy "public read designs" on public.designs for select using (true);
drop policy if exists "owner writes designs" on public.designs;
create policy "owner writes designs" on public.designs for all to authenticated using (true) with check (true);

drop policy if exists "public read settings" on public.settings;
create policy "public read settings" on public.settings for select using (true);
drop policy if exists "owner writes settings" on public.settings;
create policy "owner writes settings" on public.settings for update to authenticated using (true) with check (true);

-- مخزن الصور (عام للقراءة)
insert into storage.buckets (id, name, public) values ('designs', 'designs', true)
on conflict (id) do update set public = true;

drop policy if exists "public read images" on storage.objects;
create policy "public read images" on storage.objects for select using (bucket_id = 'designs');
drop policy if exists "owner uploads images" on storage.objects;
create policy "owner uploads images" on storage.objects for insert to authenticated with check (bucket_id = 'designs');
drop policy if exists "owner deletes images" on storage.objects;
create policy "owner deletes images" on storage.objects for delete to authenticated using (bucket_id = 'designs');
