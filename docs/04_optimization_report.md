# Optimization report

Indexes are documented in sql/05_indexes.sql; rewritten statements are in
sql/06_optimized_queries.sql. Each result below is the mean of three measured runs.

| Query | Before | After | Change | Main reason |
|---|---:|---:|---:|---|
| R01 | 8.314 | .831 | 90.0% | time/track index |
| R03 | 8.019 | 2.571 | 67.9% | trigram index |
| R04 | 5.239 | .048 | 99.1% | user/time covering index |
| R07 | 11.597 | 8.043 | 30.6% | partial royalty index |
| R08 | 12.759 | .820 | 93.6% | artist/track and track/time indexes |
| R09 | 7.124 | .085 | 98.8% | sargable date range |
| R10 | 11.225 | 3.079 | 72.6% | sargable time range |
| R11 | .451 | .067 | 85.1% | artist/release index |
| R12 | 21.028 | 8.424 | 59.9% | ordered streams index |
| R13 | 24.719 | 2.344 | 90.5% | correct anti-join + playlist index |
| R15 | 2.015 | .593 | 70.6% | artist/follower index |
| R16 | 18.788 | 10.213 | 45.6% | time index |
| R17 | 12.309 | 3.845 | 68.8% | time index |
| R19 | 9066.642 | 32.994 | 99.6% | one grouped aggregate |
| R23 | 45.783 | 12.023 | 73.7% | descending covering index |
| R25 | 14.726 | 1.035 | 93.0% | release and track indexes |

Other queries were already fast or necessarily aggregate most rows: R02, R05, R06,
R14, R18, R20, R21, R22 and R24 remain effectively unchanged. Write overhead is
small (W01 .497→.663 ms, W02 .463→.533 ms, W03 .396→.442 ms) and acceptable for
much faster reads; W04 improved 41.911→32.182 ms and W05 7.547→6.595 ms.

The original R13 is wrong: its NOT IN subquery includes NULL playlist IDs, so SQL's
three-valued logic makes the predicate UNKNOWN for every playlist. NOT EXISTS preserves
the intended result and measured 2.344 ms. Rewritten R09/R10 were compared against
their originals under the same timezone; R19 produces the same count/max values through
a left join; R13 intentionally corrects the documented NULL bug.

Largest created indexes: streams_user_started_desc_idx and streams_started_desc_idx are
12 MB each; streams_track_started_idx is 7.5 MB; streams_started_at_track_idx is 7.5 MB;
the trigram index is 2.2 MB. These sizes are reasonable for the 250,000-row streams
table and are the trade-off behind the measured write overhead.
