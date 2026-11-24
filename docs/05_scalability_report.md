# CP4: large-data scalability report

The supplied 20× dataset was loaded into a separate PostgreSQL 18 database, indexed
with sql/05_indexes.sql, and measured with the same three-run EXPLAIN (ANALYZE,
BUFFERS) method used for CP3. Full plans and exact values are in
benchmarks/results/large/. It contains 5,000,000 streams, 2,400,008 playlist entries,
1,360,381 tracks and 600,000 users. Database size was **2.5 GB**: heap-table storage
was **894 MB** and indexes were **1.6 GB**. The streams relation (including its indexes)
was the largest at **1.4 GB**.

| Query | Seed optimized ms | Large optimized ms | Growth | Target |
|---|---:|---:|---:|---|
| R01 | .831 | 6.537 | 7.9× | ✅ <250 |
| R02 | .023 | .222 | 9.7× | ✅ <5 |
| R03 | 2.571 | 68.372 | 26.6× | ✅ <250 |
| R04 | .048 | .364 | 7.6× | ✅ <5 |
| R05 | .137 | 1.582 | 11.5× | ✅ <5 |
| R06 | .052 | .214 | 4.1× | ✅ <5 |
| R07 | 8.043 | 98.172 | 12.2× | ✅ <5000 |
| R08 | .820 | 7.910 | 9.6× | ✅ <250 |
| R09 | .085 | .593 | 7.0× | ✅ <250 |
| R10 | 3.079 | 73.613 | 23.9× | ✅ <5000 |
| R11 | .067 | .587 | 8.8× | ✅ <5 |
| R12 | 8.424 | 99.505 | 11.8× | ✅ <5000 |
| R13 | 2.344 | 49.227 | 21.0× | ✅ <250 |
| R14 | 8.354 | 102.244 | 12.2× | ✅ <5000 |
| R15 | .593 | 21.624 | 36.5× | ✅ <250 |
| R16 | 10.213 | 136.363 | 13.4× | ✅ <5000 |
| R17 | 3.845 | 119.274 | 31.0× | ✅ <5000 |
| R18 | 16.607 | 214.214 | 12.9× | ✅ <5000 |
| R19 | 32.994 | 867.845 | 26.3× | ✅ <5000 |
| R20 | 141.582 | 2062.952 | 14.6× | ✅ <5000 |
| R21 | .030 | .142 | 4.7× | ✅ <5 |
| R22 | 23.260 | 259.043* | 11.1× | ⚠️ 9.0 ms over |
| R23 | 12.023 | 11.895 | 1.0× | ✅ <5000 |
| R24 | 11.883 | 112.228 | 9.4× | ✅ <5000 |
| R25 | 1.035 | 70.131 | 67.8× | ✅ <250 |
| W01 | .663 | 1.136 | 1.7× | ✅ <5 |
| W02 | .533 | .793 | 1.5× | ✅ <5 |
| W03 | .442 | .585 | 1.3× | ✅ <5 |
| W04 | 32.182 | 933.985 | 29.0× | ✅ <3000 |
| W05 | 6.595 | 140.882 | 21.4× | ✅ <250 |

*The initial three-pass large run recorded R22 at 526.379 ms. The final three-pass run
after adding playlist_tracks(playlist_id, track_id) measured 259.043 ms. The index
replaces a hash aggregate with an index-only ordered GroupAggregate, but the query still
must inspect 2.4M rows and sort 36,000 duplicate groups. It narrowly misses the
interactive target; a maintained duplicate counter/materialized view is the next step
if the target is strict.

## Growth analysis

Point lookups and bounded history (R02, R04, R06, R11, R21, W01–W03) stayed close to
constant because their composite indexes locate a small row set. Date-range and
join-heavy reports generally grew around 10–30× because they read a fixed month or
large portion of an enlarged event table. R25 grew more than 20× because it joins
recent releases to a much larger stream history. R20 is the largest read at 2.06 s;
it deliberately aggregates all streams and still meets the 5 s reporting budget.

## 100× design

sql/08_partitioning.sql partitions streams monthly by started_at. It enables partition
pruning for monthly reports (R07, R10, R17) and keeps indexes/vacuum work bounded to
recent partitions. The required partitioned primary key is (stream_id, started_at):
PostgreSQL requires the partition key in a partitioned primary/unique key.

For sharding, hash by user_id for Recently Played, Liked Songs and user write paths;
royalty and artist reports then become cross-shard aggregations and should run in a
warehouse/aggregate service. Time-based archival remains local to each user shard.
Send dashboards, search and catalogue reads to replicas; cache popular artist/album
pages briefly. Stream writes, likes and playlist mutation must go to the primary.
Autovacuum should prioritize current stream partitions; detach/archive old monthly
partitions and refresh any duplicate or artist-listener summary after the nightly load.

Conclusion: all required large-data targets are met except the explicitly documented
R22 near miss. The indexed design is ready for the observed 20× load; at 100×, monthly
partitioning plus asynchronous summaries for whole-table analytics are required.
