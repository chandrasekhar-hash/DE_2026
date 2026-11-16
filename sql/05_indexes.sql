-- Phase 4 tuning indexes. Primary-key and UNIQUE indexes already existed in
-- the baseline; every index below targets an observed workload access path.
SET search_path TO spotify;

-- R01/R07/R10/R16/R17: time windows over the large append-heavy streams table.
CREATE INDEX streams_started_at_track_idx ON streams (started_at, track_id);
-- R04 and R09: one listener's most recent history, already in requested order.
CREATE INDEX streams_user_started_desc_idx
  ON streams (user_id, started_at DESC) INCLUDE (track_id, ms_played, platform);
-- R07: smaller index for the royalty-eligible slice.
CREATE INDEX streams_royalty_started_track_idx
  ON streams (started_at, track_id) WHERE ms_played >= 30000;
-- R08/R19/R25/W05: joins from a known track to its streams.
CREATE INDEX streams_track_started_idx ON streams (track_id, started_at DESC);
-- R13: anti-join only needs playlists that have actually been streamed.
CREATE INDEX streams_playlist_id_idx ON streams (playlist_id) WHERE playlist_id IS NOT NULL;
-- R23: avoids sorting all streams before an ordered support-console page.
CREATE INDEX streams_started_desc_idx
  ON streams (started_at DESC) INCLUDE (stream_id, user_id, track_id, ms_played);

-- R01/R08/R15/R16/R19 and R11: find the small relationship set first.
CREATE INDEX track_artists_artist_track_idx ON track_artists (artist_id, track_id);
CREATE INDEX artist_follows_artist_user_idx ON artist_follows (artist_id, user_id);
CREATE INDEX albums_artist_release_idx ON albums (artist_id, release_date DESC);
CREATE INDEX albums_release_idx ON albums (release_date);

-- R03: substring search needs trigrams; a B-tree cannot support '%love%'.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX tracks_title_trgm_idx ON tracks USING gin (title gin_trgm_ops);

-- R11/R14's user/playlist lookups and R06's requested order.
CREATE INDEX artist_follows_user_followed_idx ON artist_follows (user_id, followed_at DESC);
CREATE INDEX liked_tracks_user_liked_desc_idx ON liked_tracks (user_id, liked_at DESC) INCLUDE (track_id);

ANALYZE;
