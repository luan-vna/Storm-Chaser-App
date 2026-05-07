# Supabase setup (optional)

The app runs **fully offline** without Supabase configured: weather caches
locally, storm reports persist in SwiftData, and the cloud sync coordinator
becomes a silent no-op. Configure the two values below to enable cloud upload.

## 1. Create the Supabase project

In your Supabase dashboard:

1. **Authentication → Providers → Anonymous Sign-Ins → enable.**
2. Run this SQL in the SQL editor:

```sql
create table storm_reports (
    id              uuid primary key default gen_random_uuid(),
    client_id       uuid not null,
    user_id         uuid not null references auth.users(id) on delete cascade,
    created_at      timestamptz not null default now(),
    captured_at     timestamptz not null,
    storm_type      text not null,
    latitude        double precision not null,
    longitude       double precision not null,
    notes           text not null default '',
    temperature_c   double precision,
    wind_speed_kph  double precision,
    precipitation_mm double precision,
    weather_conditions text,
    photo_path      text,
    unique (user_id, client_id)
);

alter table storm_reports enable row level security;

create policy "owner insert" on storm_reports
    for insert to authenticated
    with check (auth.uid() = user_id);

create policy "owner select" on storm_reports
    for select to authenticated
    using (auth.uid() = user_id);
```

3. **Storage → New bucket → `storm-photos`** (private). Then in Storage > Policies:

```sql
create policy "owner upload photos"
    on storage.objects for insert to authenticated
    with check (
        bucket_id = 'storm-photos'
        and auth.uid()::text = (storage.foldername(name))[1]
    );

create policy "owner read photos"
    on storage.objects for select to authenticated
    using (
        bucket_id = 'storm-photos'
        and auth.uid()::text = (storage.foldername(name))[1]
    );
```

## 2. Wire your credentials

Two values needed (find them in **Project Settings → API**):

- `SUPABASE_URL` — `https://PROJECT_ID.supabase.co`
- `SUPABASE_ANON_KEY` — the **anon (public)** key. **Never** the `service_role`.