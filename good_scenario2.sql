INSERT INTO a SELECT gs%5 AS gs, 2 as y FROM generate_series(1,1E3) AS gs;
EXPLAIN (ANALYZE, COSTS ON)
SELECT count(*) FROM a,b WHERE a.x=b.x AND a.y = 2;

--                                                    QUERY PLAN
-- -----------------------------------------------------------------------------------------------------------------
--  Aggregate  (cost=5247.23..5247.24 rows=1 width=8) (actual time=126.854..126.856 rows=1 loops=1)
--    ->  Nested Loop  (cost=0.00..5246.73 rows=200 width=0) (actual time=4.992..121.278 rows=200800 loops=1)
--          Join Filter: (a.x = b.x)
--          Rows Removed by Join Filter: 809200
--          ->  Seq Scan on a  (cost=0.00..5219.00 rows=1 width=4) (actual time=4.969..5.097 rows=1000 loops=1)
--                Filter: (y = '2'::numeric)
--          ->  Seq Scan on b  (cost=0.00..15.10 rows=1010 width=5) (actual time=0.002..0.040 rows=1010 loops=1000)
--  Planning Time: 0.256 ms
--  Execution Time: 126.895 ms
-- (9 rows)

set switch_join.enable=on;
EXPLAIN (ANALYZE, COSTS ON)
SELECT count(*) FROM a,b WHERE a.x=b.x AND a.y = 2;
--                                                           QUERY PLAN
-- -------------------------------------------------------------------------------------------------------------------------------
--  Aggregate  (cost=5277.48..5277.49 rows=1 width=8) (actual time=42.306..42.310 rows=1 loops=1)
--    ->  Custom Scan (SwitchJoin)  (cost=27.73..5276.98 rows=200 width=0) (actual time=5.269..35.589 rows=200800 loops=1)
--          --> Limit cardinality: 400
--          ->  Nested Loop  (cost=0.00..5249.25 rows=200 width=0) (never executed)
--                Join Filter: (a.x = b.x)
--                ->  Materialize  (cost=0.00..20.15 rows=1010 width=5) (actual time=0.013..0.205 rows=705 loops=2)
--                      ->  Seq Scan on b  (cost=0.00..15.10 rows=1010 width=5) (actual time=0.012..0.103 rows=705 loops=2)
--                ->  Materialize  (cost=0.00..5219.01 rows=1 width=4) (never executed)
--                      ->  Seq Scan on a  (cost=0.00..5219.00 rows=1 width=4) (never executed)
--                            Filter: (y = '2'::numeric)
--          ->  Hash Join  (cost=27.73..5249.98 rows=200 width=0) (actual time=5.113..26.358 rows=200800 loops=1)
--                Hash Cond: (a.x = b.x)
--                ->  Seq Scan on a  (cost=0.00..5219.00 rows=1 width=4) (actual time=4.594..4.733 rows=1000 loops=1)
--                      Filter: (y = '2'::numeric)
--                ->  Hash  (cost=20.15..20.15 rows=1010 width=5) (actual time=0.512..0.512 rows=1010 loops=1)
--                      Buckets: 1024  Batches: 1  Memory Usage: 45kB
--                      ->  Materialize  (cost=0.00..20.15 rows=1010 width=5) (actual time=0.013..0.205 rows=705 loops=2)
--                            ->  Seq Scan on b  (cost=0.00..15.10 rows=1010 width=5) (actual time=0.012..0.103 rows=705 loops=2)
--  Planning Time: 0.225 ms
--  Execution Time: 42.358 ms