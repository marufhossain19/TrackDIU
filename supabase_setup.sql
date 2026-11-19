-- ================================================================
-- TrackDIU — Supabase Setup SQL (Full Reset + Recreate)
-- Run this entirely in your Supabase SQL Editor.
-- It drops existing objects first so it is safe to re-run.
-- ================================================================

-- ============================================================
-- 0. TEARDOWN — drop in reverse-dependency order
-- ============================================================
DROP TABLE IF EXISTS driver_requests  CASCADE;
DROP TABLE IF EXISTS driver_profiles  CASCADE;
DROP TABLE IF EXISTS bus_locations    CASCADE;
DROP TABLE IF EXISTS schedules        CASCADE;
DROP TABLE IF EXISTS buses            CASCADE;

-- ============================================================
-- 1. BUSES TABLE
-- ============================================================
CREATE TABLE buses (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  number     TEXT        NOT NULL,
  route      TEXT        NOT NULL,
  stops      JSONB       NOT NULL DEFAULT '[]',
  is_active  BOOLEAN     NOT NULL DEFAULT FALSE,
  device_id  TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. BUS LOCATIONS TABLE  (real-time driver GPS updates)
-- ============================================================
CREATE TABLE bus_locations (
  id           UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
  bus_id       UUID             NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
  latitude     DOUBLE PRECISION NOT NULL,
  longitude    DOUBLE PRECISION NOT NULL,
  speed        DOUBLE PRECISION,
  current_stop TEXT,
  updated_at   TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  UNIQUE (bus_id)          -- one live-location row per bus
);

-- ============================================================
-- 3. SCHEDULES TABLE
-- ============================================================
CREATE TABLE schedules (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  bus_id         UUID        NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
  departure_time TEXT        NOT NULL,   -- e.g. "07:00"
  origin         TEXT        NOT NULL,
  destination    TEXT        NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 4. DRIVER PROFILES TABLE
--    Created automatically on first profile save.
--    bus_number / bus_id are populated when admin approves
--    a bus_assignment request.
-- ============================================================
CREATE TABLE driver_profiles (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    TEXT        NOT NULL UNIQUE,   -- auth.uid()
  name       TEXT        NOT NULL DEFAULT '',
  bus_number TEXT,                          -- confirmed bus number, e.g. "B-01"
  bus_id     UUID        REFERENCES buses(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 5. DRIVER REQUESTS TABLE
--    type   : 'bus_assignment' | 'location_sharing'
--    status : 'pending'        | 'approved' | 'rejected'
--    valid_date: the calendar date the request/approval is for
-- ============================================================
CREATE TABLE driver_requests (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_user_id  TEXT        NOT NULL,           -- auth.uid() of driver
  driver_name     TEXT        NOT NULL,
  type            TEXT        NOT NULL,            -- 'bus_assignment' | 'location_sharing'
  requested_bus   TEXT,                            -- bus number driver asked for
  assigned_bus    TEXT,                            -- bus number admin confirmed (may differ)
  assigned_bus_id UUID        REFERENCES buses(id) ON DELETE SET NULL,
  status          TEXT        NOT NULL DEFAULT 'pending',
  valid_date      DATE        NOT NULL DEFAULT CURRENT_DATE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at     TIMESTAMPTZ
);

-- ============================================================
-- 6. ENABLE REALTIME
--    bus_locations  → students / map screen track live buses
--    driver_requests → driver gets instant approval notification
--    driver_profiles → admin panel sees profile updates live
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE bus_locations;
ALTER PUBLICATION supabase_realtime ADD TABLE driver_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE driver_profiles;

-- ============================================================
-- 7. ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE buses            ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_locations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules        ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_profiles  ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_requests  ENABLE ROW LEVEL SECURITY;

-- ── Public reads (no login required) ────────────────────────
CREATE POLICY "Public read buses"
  ON buses FOR SELECT USING (true);

CREATE POLICY "Public read bus_locations"
  ON bus_locations FOR SELECT USING (true);

CREATE POLICY "Public read schedules"
  ON schedules FOR SELECT USING (true);

-- ── Driver: read / write own profile ────────────────────────
CREATE POLICY "Driver read own profile"
  ON driver_profiles FOR SELECT
  USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Driver insert own profile"
  ON driver_profiles FOR INSERT
  WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Driver update own profile"
  ON driver_profiles FOR UPDATE
  USING (auth.uid()::TEXT = user_id);

-- ── Driver: read own requests + insert new ones ─────────────
CREATE POLICY "Driver read own requests"
  ON driver_requests FOR SELECT
  USING (auth.uid()::TEXT = driver_user_id);

CREATE POLICY "Driver insert request"
  ON driver_requests FOR INSERT
  WITH CHECK (auth.uid()::TEXT = driver_user_id);

-- ── Driver: push GPS location (authenticated only) ──────────
CREATE POLICY "Driver insert location"
  ON bus_locations FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Driver update location"
  ON bus_locations FOR UPDATE
  USING  (auth.role() = 'authenticated');

-- ── Admin: full access on buses ─────────────────────────────
-- Both WITH CHECK clauses are required — without them RLS
-- silently blocks admin INSERTs.
CREATE POLICY "Admin full access buses"
  ON buses FOR ALL
  USING (
    (auth.jwt() ->> 'role') = 'admin'
    OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  )
  WITH CHECK (
    (auth.jwt() ->> 'role') = 'admin'
    OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- ── Admin: full access on schedules ─────────────────────────
CREATE POLICY "Admin full access schedules"
  ON schedules FOR ALL
  USING (
    (auth.jwt() ->> 'role') = 'admin'
    OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  )
  WITH CHECK (
    (auth.jwt() ->> 'role') = 'admin'
    OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- ── Admin: full access on driver_profiles ───────────────────
CREATE POLICY "Admin full access driver_profiles"
  ON driver_profiles FOR ALL
  USING  ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── Admin: full access on driver_requests ───────────────────
--    (approve / reject requests, update status + assigned_bus)
CREATE POLICY "Admin full access driver_requests"
  ON driver_requests FOR ALL
  USING  ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ============================================================
-- 8. SAMPLE DATA
-- ============================================================

-- ── Buses ────────────────────────────────────────────────────
INSERT INTO buses (id, number, route, stops, is_active) VALUES
  ('11111111-1111-1111-1111-111111111111', 'B-01', 'Mirpur → DIU Campus',
    '["Mirpur-1","Mirpur-10","Gabtoli","DIU Campus"]', true),
  ('22222222-2222-2222-2222-222222222222', 'B-02', 'Dhanmondi → DIU Campus',
    '["Dhanmondi-27","Science Lab","DIU Campus"]', true),
  ('33333333-3333-3333-3333-333333333333', 'B-03', 'Uttara → DIU Campus',
    '["Uttara Sector-7","Abdullahpur","DIU Campus"]', false),
  ('44444444-4444-4444-4444-444444444444', 'B-04', 'Motijheel → DIU Campus',
    '["Motijheel","Paltan","Tejgaon","DIU Campus"]', false),
  ('55555555-5555-5555-5555-555555555555', 'B-05', 'Gazipur → DIU Campus',
    '["Gazipur Chowrasta","Tongi","DIU Campus"]', false)
ON CONFLICT (id) DO NOTHING;

-- ── Schedules ────────────────────────────────────────────────
INSERT INTO schedules (bus_id, departure_time, origin, destination) VALUES
  ('11111111-1111-1111-1111-111111111111', '07:00', 'Mirpur-1',        'DIU Campus'),
  ('11111111-1111-1111-1111-111111111111', '12:00', 'Mirpur-1',        'DIU Campus'),
  ('11111111-1111-1111-1111-111111111111', '17:00', 'Mirpur-1',        'DIU Campus'),
  ('22222222-2222-2222-2222-222222222222', '07:30', 'Dhanmondi-27',    'DIU Campus'),
  ('22222222-2222-2222-2222-222222222222', '12:30', 'Dhanmondi-27',    'DIU Campus'),
  ('22222222-2222-2222-2222-222222222222', '17:30', 'Dhanmondi-27',    'DIU Campus'),
  ('33333333-3333-3333-3333-333333333333', '06:45', 'Uttara Sector-7', 'DIU Campus'),
  ('33333333-3333-3333-3333-333333333333', '16:45', 'Uttara Sector-7', 'DIU Campus'),
  ('44444444-4444-4444-4444-444444444444', '07:15', 'Motijheel',       'DIU Campus'),
  ('44444444-4444-4444-4444-444444444444', '12:15', 'Motijheel',       'DIU Campus'),
  ('44444444-4444-4444-4444-444444444444', '17:15', 'Motijheel',       'DIU Campus'),
  ('55555555-5555-5555-5555-555555555555', '07:00', 'Gazipur Chowrasta','DIU Campus'),
  ('55555555-5555-5555-5555-555555555555', '12:00', 'Gazipur Chowrasta','DIU Campus'),
  ('55555555-5555-5555-5555-555555555555', '17:00', 'Gazipur Chowrasta','DIU Campus')
ON CONFLICT DO NOTHING;

-- ── Seed live bus locations ───────────────────────────────────
INSERT INTO bus_locations (bus_id, latitude, longitude, speed, current_stop) VALUES
  ('11111111-1111-1111-1111-111111111111', 23.8728, 90.3984, 35.5, 'Gabtoli'),
  ('22222222-2222-2222-2222-222222222222', 23.8800, 90.4020, 28.3, 'Science Lab')
ON CONFLICT (bus_id) DO UPDATE
  SET latitude   = EXCLUDED.latitude,
      longitude  = EXCLUDED.longitude,
      speed      = EXCLUDED.speed,
      updated_at = NOW();