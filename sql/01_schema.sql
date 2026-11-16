-- Spotify Music Streaming Database — baseline schema (PostgreSQL 15+)
-- This file deliberately creates constraints only. Performance indexes belong in
-- sql/05_indexes.sql so the baseline benchmark remains untuned.

CREATE SCHEMA spotify;
SET search_path TO spotify;

CREATE TABLE artists (
  artist_id         INTEGER PRIMARY KEY,
  artist_name       TEXT NOT NULL CHECK (btrim(artist_name) <> ''),
  country_code      CHAR(2) NOT NULL CHECK (country_code ~ '^[A-Z]{2}$'),
  primary_genre     TEXT NOT NULL CHECK (btrim(primary_genre) <> ''),
  is_verified       BOOLEAN NOT NULL DEFAULT FALSE,
  monthly_listeners INTEGER NOT NULL DEFAULT 0 CHECK (monthly_listeners >= 0),
  created_at        TIMESTAMPTZ NOT NULL
);

CREATE TABLE users (
  user_id      INTEGER PRIMARY KEY,
  email        TEXT NOT NULL UNIQUE CHECK (email ~* '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'),
  display_name TEXT NOT NULL CHECK (btrim(display_name) <> ''),
  country_code CHAR(2) NOT NULL CHECK (country_code ~ '^[A-Z]{2}$'),
  birth_date   DATE NOT NULL CHECK (birth_date >= DATE '1900-01-01'),
  subscription TEXT NOT NULL CHECK (subscription IN ('FREE', 'PREMIUM', 'DUO', 'FAMILY', 'STUDENT')),
  created_at   TIMESTAMPTZ NOT NULL
);

CREATE TABLE albums (
  album_id     INTEGER PRIMARY KEY,
  artist_id    INTEGER NOT NULL REFERENCES artists(artist_id) ON DELETE RESTRICT,
  album_title  TEXT NOT NULL CHECK (btrim(album_title) <> ''),
  album_type   TEXT NOT NULL CHECK (album_type IN ('ALBUM', 'EP', 'SINGLE', 'COMPILATION')),
  release_date DATE NOT NULL,
  label        TEXT NOT NULL CHECK (btrim(label) <> ''),
  upc          CHAR(12) NOT NULL UNIQUE CHECK (upc ~ '^[0-9]{12}$')
);

CREATE TABLE tracks (
  track_id    INTEGER PRIMARY KEY,
  album_id    INTEGER NOT NULL REFERENCES albums(album_id) ON DELETE CASCADE,
  disc_no     SMALLINT NOT NULL CHECK (disc_no > 0),
  track_no    SMALLINT NOT NULL CHECK (track_no > 0),
  title       TEXT NOT NULL CHECK (btrim(title) <> ''),
  duration_ms INTEGER NOT NULL CHECK (duration_ms BETWEEN 1 AND 3600000),
  explicit    BOOLEAN NOT NULL DEFAULT FALSE,
  isrc        CHAR(12) NOT NULL UNIQUE CHECK (isrc ~ '^[A-Z]{2}[A-Z0-9]{3}[0-9]{7}$'),
  popularity  SMALLINT NOT NULL CHECK (popularity BETWEEN 0 AND 100),
  UNIQUE (album_id, disc_no, track_no)
);

CREATE TABLE track_artists (
  track_id  INTEGER NOT NULL REFERENCES tracks(track_id) ON DELETE CASCADE,
  artist_id INTEGER NOT NULL REFERENCES artists(artist_id) ON DELETE RESTRICT,
  role      TEXT NOT NULL CHECK (role IN ('PRIMARY', 'FEATURED')),
  PRIMARY KEY (track_id, artist_id)
);

CREATE TABLE playlists (
  playlist_id      INTEGER PRIMARY KEY,
  owner_user_id    INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  name             TEXT NOT NULL CHECK (btrim(name) <> ''),
  is_public        BOOLEAN NOT NULL DEFAULT FALSE,
  is_collaborative BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ NOT NULL,
  -- The supplied export has no public collaborative playlist. Treating these
  -- as separate sharing modes keeps the visibility rule unambiguous.
  CHECK (NOT (is_public AND is_collaborative))
);

CREATE TABLE playlist_tracks (
  playlist_id      INTEGER NOT NULL REFERENCES playlists(playlist_id) ON DELETE CASCADE,
  position         INTEGER NOT NULL CHECK (position > 0),
  track_id         INTEGER NOT NULL REFERENCES tracks(track_id) ON DELETE RESTRICT,
  added_by_user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  added_at         TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (playlist_id, position)
);

CREATE TABLE streams (
  stream_id   BIGINT PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  track_id    INTEGER NOT NULL REFERENCES tracks(track_id) ON DELETE RESTRICT,
  started_at  TIMESTAMPTZ NOT NULL,
  ms_played   INTEGER NOT NULL CHECK (ms_played >= 0),
  platform    TEXT NOT NULL CHECK (platform IN ('ANDROID', 'IOS', 'DESKTOP', 'WEB', 'SPEAKER', 'CAR')),
  source_type TEXT NOT NULL CHECK (source_type IN ('ALBUM', 'ARTIST', 'PLAYLIST', 'RADIO', 'SEARCH')),
  playlist_id INTEGER REFERENCES playlists(playlist_id) ON DELETE SET NULL,
  skipped     BOOLEAN NOT NULL DEFAULT FALSE,
  offline     BOOLEAN NOT NULL DEFAULT FALSE,
  CHECK ((source_type = 'PLAYLIST') = (playlist_id IS NOT NULL)),
  CHECK (NOT skipped OR ms_played < 30000)
);

CREATE TABLE liked_tracks (
  user_id  INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  track_id INTEGER NOT NULL REFERENCES tracks(track_id) ON DELETE CASCADE,
  liked_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (user_id, track_id)
);

CREATE TABLE artist_follows (
  user_id     INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  artist_id   INTEGER NOT NULL REFERENCES artists(artist_id) ON DELETE CASCADE,
  followed_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (user_id, artist_id)
);
