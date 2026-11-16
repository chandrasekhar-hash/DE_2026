# Baseline timing results

Measured locally with PostgreSQL 18 using EXPLAIN (ANALYZE, BUFFERS), three runs
per query. Full plans are in benchmarks/results/baseline; values are milliseconds.

| Query | Type | Run 1 | Run 2 | Run 3 | Avg | Dominant scan / observation |
|---|---|---:|---:|---:|---:|---|
| R01 | READ | 7.789 | 7.911 | 9.242 | 8.314 | Seq streams |
| R02 | READ | .023 | .025 | .025 | .024 | album unique index |
| R03 | READ | 7.952 | 8.001 | 8.103 | 8.019 | Seq tracks |
| R04 | READ | 5.174 | 5.213 | 5.330 | 5.239 | Seq streams |
| R05 | READ | .130 | .143 | .145 | .139 | playlist PK |
| R06 | READ | .041 | .044 | .054 | .046 | liked PK |
| R07 | READ | 11.238 | 11.606 | 11.947 | 11.597 | Seq streams |
| R08 | READ | 10.475 | 13.292 | 14.511 | 12.759 | Seq streams |
| R09 | READ | 6.105 | 7.141 | 8.126 | 7.124 | Seq streams |
| R10 | READ | 10.685 | 10.804 | 12.187 | 11.225 | Seq streams |
| R11 | READ | .437 | .443 | .472 | .451 | Seq albums |
| R12 | READ | 19.382 | 19.849 | 23.852 | 21.028 | Seq streams |
| R13 | READ | 22.934 | 23.887 | 27.337 | 24.719 | Seq streams |
| R14 | READ | 8.427 | 8.458 | 8.485 | 8.457 | Seq playlist_tracks |
| R15 | READ | 1.878 | 1.885 | 2.281 | 2.015 | Seq follows |
| R16 | READ | 18.492 | 18.703 | 19.169 | 18.788 | Seq streams |
| R17 | READ | 12.023 | 12.241 | 12.663 | 12.309 | Seq streams |
| R18 | READ | 17.242 | 19.505 | 24.205 | 20.317 | Seq streams |
| R19 | READ | 8890.527 | 9053.267 | 9256.133 | 9066.642 | repeated Seq streams |
| R20 | READ | 140.720 | 142.173 | 143.124 | 142.006 | Seq streams |
| R21 | READ | .027 | .029 | .034 | .030 | ISRC unique index |
| R22 | READ | 23.108 | 23.260 | 23.397 | 23.255 | Seq playlist_tracks |
| R23 | READ | 45.442 | 45.788 | 46.118 | 45.783 | Seq/sort streams |
| R24 | READ | 12.093 | 12.158 | 12.291 | 12.181 | Seq tracks |
| R25 | READ | 14.705 | 14.732 | 14.741 | 14.726 | Seq streams |
| W01 | WRITE | .484 | .487 | .519 | .497 | insert + FK checks |
| W02 | WRITE | .414 | .467 | .508 | .463 | insert/upsert |
| W03 | WRITE | .351 | .399 | .437 | .396 | playlist PK |
| W04 | WRITE | 41.560 | 41.621 | 42.552 | 41.911 | streams aggregate |
| W05 | WRITE | 6.882 | 6.968 | 8.791 | 7.547 | Seq playlist_tracks |

The unspecialized baseline uses only constraint indexes. R19 is the clear outlier:
two correlated subqueries rescan streams for each verified artist.
