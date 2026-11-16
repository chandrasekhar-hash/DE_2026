# Schema design and load verification

sql/01_schema.sql creates ten normalized tables in spotify; sql/02_load_data.sql
loaded every supplied CSV on PostgreSQL 18 without rejected rows. The ER diagram is
[er_diagram.svg](../diagrams/er_diagram.svg).

| Table | Key(s) | Important attributes and rules |
|---|---|---|
| artists | artist_id | country code, non-negative cached monthly listeners |
| albums | album_id; upc unique | artist FK; type is ALBUM/EP/SINGLE/COMPILATION |
| tracks | track_id; isrc unique; album/disc/track unique | album FK, positive duration, popularity 0–100 |
| track_artists | (track_id,artist_id) | M:N bridge; role PRIMARY/FEATURED |
| users | user_id; email unique | country, birth date, constrained subscription |
| playlists | playlist_id | owner FK; cannot be public and collaborative simultaneously |
| playlist_tracks | (playlist_id,position) | playlist, track and adding-user FKs; duplicates are permitted |
| streams | stream_id | user/track FKs; playlist FK is present iff source is PLAYLIST; skipped streams are under 30 seconds |
| liked_tracks | (user_id,track_id) | user and track bridge with liked_at |
| artist_follows | (user_id,artist_id) | user and artist bridge with followed_at |

Delete policy is deliberately conservative for music, users and streams (RESTRICT);
dependent bridge rows cascade with their parent user/track/playlist where their independent
meaning ends. Playlist references on a deleted playlist become NULL in historical streams.

Functional dependencies are id → every non-key attribute for entity tables. In bridge
tables the composite key determines the relationship attributes. Therefore each table is
in 3NF and BCNF under the documented business keys. The denormalized
artists.monthly_listeners is retained as a materialized dashboard value and is regenerated
by W04; streams.skipped records an explicit player action rather than merely deriving
from duration.

Load row counts: artists 3,000; albums 12,000; tracks 67,808; track_artists 77,489;
users 30,000; playlists 10,000; playlist_tracks 120,004; streams 250,000;
liked_tracks 58,533; artist_follows 69,901.

Integrity checks after loading: exactly-one-primary-artist violations **0**; streams longer
than their track **0**; playlist source/id mismatches **0**; streams before album release
**0**. The supplied data contains 137,386 NULL streams.playlist_id values; these are
valid because those rows are not playlist-sourced.
