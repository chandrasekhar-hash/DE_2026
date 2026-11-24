-- CP4 design for the next 100×: partition the append-heavy event table by month.
-- This is a forward migration design; it does not alter the measured streams table.
-- PostgreSQL requires every partition key to occur in a partitioned-table unique
-- or primary key, hence the composite primary key below.
CREATE TABLE spotify.streams_partitioned (
  stream_id BIGINT NOT NULL,
  user_id INTEGER NOT NULL REFERENCES spotify.users(user_id) ON DELETE RESTRICT,
  track_id INTEGER NOT NULL REFERENCES spotify.tracks(track_id) ON DELETE RESTRICT,
  started_at TIMESTAMPTZ NOT NULL,
  ms_played INTEGER NOT NULL CHECK (ms_played >= 0),
  platform TEXT NOT NULL CHECK (platform IN ('ANDROID','IOS','DESKTOP','WEB','SPEAKER','CAR')),
  source_type TEXT NOT NULL CHECK (source_type IN ('ALBUM','ARTIST','PLAYLIST','RADIO','SEARCH')),
  playlist_id INTEGER REFERENCES spotify.playlists(playlist_id) ON DELETE SET NULL,
  skipped BOOLEAN NOT NULL DEFAULT FALSE,
  offline BOOLEAN NOT NULL DEFAULT FALSE,
  CHECK ((source_type = 'PLAYLIST') = (playlist_id IS NOT NULL)),
  CHECK (NOT skipped OR ms_played < 30000),
  PRIMARY KEY (stream_id, started_at)
) PARTITION BY RANGE (started_at);

CREATE TABLE spotify.streams_2026_01 PARTITION OF spotify.streams_partitioned
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE spotify.streams_2026_02 PARTITION OF spotify.streams_partitioned
  FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE spotify.streams_2026_03 PARTITION OF spotify.streams_partitioned
  FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE spotify.streams_2026_04 PARTITION OF spotify.streams_partitioned
  FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE spotify.streams_2026_05 PARTITION OF spotify.streams_partitioned
  FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE spotify.streams_2026_06 PARTITION OF spotify.streams_partitioned
  FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

-- Supporting indexes are created per partition by the partitioned parent index.
CREATE INDEX streams_partitioned_user_started_idx
  ON spotify.streams_partitioned (user_id, started_at DESC);
CREATE INDEX streams_partitioned_track_started_idx
  ON spotify.streams_partitioned (track_id, started_at DESC);

-- Example: this predicate prunes all partitions except streams_2026_06.
EXPLAIN (COSTS OFF)
SELECT count(*) FROM spotify.streams_partitioned
WHERE started_at >= TIMESTAMPTZ '2026-06-01 00:00:00+05:30'
  AND started_at <  TIMESTAMPTZ '2026-07-01 00:00:00+05:30';
