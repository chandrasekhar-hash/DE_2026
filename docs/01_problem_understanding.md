# Problem understanding

| Problem | Need and affected stakeholder | Work class |
|---|---|---|
| P1 | Fast artist, album and playlist pages for listeners. | Customer-facing / real-time |
| P2 | Fast search, recent history and Liked Songs for heavy listeners. | Customer-facing / real-time |
| P3 | Current skip, audience and affinity statistics for Spotify for Artists. | Interactive artist tool |
| P4 | Accurate, prompt royalty eligibility and ISRC rights lookup for labels/finance. | Reporting plus real-time lookup |
| P5 | A correct list of public playlists never played, for curation. | Reporting / analytics |
| P6 | Wrapped, Release Radar and discovery jobs must finish within their batch window. | Reporting / analytics |
| P7 | Compliance needs an auditable report of explicit content played by minors. | Reporting / analytics |
| P8 | Playlist contributors, inserts and duplicate detection must remain responsive. | Customer-facing / interactive |
| P9 | Growth needs reliable platform/usage reports as streams grow 20×. | Reporting / analytics |

Assumptions: a stream belongs to a playlist exactly when source_type is PLAYLIST; a
stream of less than 30 seconds may be marked skipped; a recording has one primary
artist and zero or more featured artists; UPC and ISRC are stable external identifiers.
monthly_listeners is a cached, recomputable value maintained by the nightly job.
