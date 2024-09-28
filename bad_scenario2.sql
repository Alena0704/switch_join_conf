DROP TABLE IF EXISTS a,b CASCADE;
CREATE TABLE a WITH (autovacuum_enabled = false) AS
  SELECT gs AS x, 5 as y FROM generate_series(1,1E1) AS gs;
CREATE TABLE b WITH (autovacuum_enabled = false) AS
  SELECT gs AS x FROM generate_series(1,1E1) AS gs;

-- It is most easy way to emulate optimizer error ...
ANALYZE a,b;
INSERT INTO a SELECT gs AS x, 5 as y FROM generate_series(1,1E2) AS gs;
INSERT INTO b SELECT 1 AS x FROM generate_series(1,1E5) AS gs;

EXPLAIN (ANALYZE, COSTS ON)
SELECT count(*) FROM a,b WHERE a.x=b.x AND a.y = 2;

set switch_join.enable=on;
--                                                        QUERY PLAN
-- ------------------------------------------------------------------------------------------------------------------------
--  Aggregate  (cost=556.02..556.03 rows=1 width=8) (actual time=0.065..0.069 rows=1 loops=1)
--    ->  Custom Scan (SwitchJoin)  (cost=1.14..556.02 rows=1 width=0) (actual time=0.062..0.065 rows=0 loops=1)
--          --> Limit cardinality: 10
--          ->  Nested Loop  (cost=0.00..554.88 rows=1 width=0) (never executed)
--                Join Filter: (a.x = b.x)
--                ->  Materialize  (cost=0.00..509.45 rows=4430 width=5) (actual time=0.014..0.016 rows=6 loops=2)
--                      ->  Seq Scan on b  (cost=0.00..487.30 rows=4430 width=5) (actual time=0.013..0.014 rows=6 loops=2)
--                ->  Materialize  (cost=0.00..1.13 rows=1 width=5) (never executed)
--                      ->  Seq Scan on a  (cost=0.00..1.12 rows=1 width=5) (never executed)
--                            Filter: (y = 2)
--          ->  Hash Join  (cost=1.14..505.06 rows=1 width=0) (actual time=0.033..0.035 rows=0 loops=1)
--                Hash Cond: (b.x = a.x)
--                ->  Materialize  (cost=0.00..509.45 rows=4430 width=5) (actual time=0.014..0.016 rows=6 loops=2)
--                      ->  Seq Scan on b  (cost=0.00..487.30 rows=4430 width=5) (actual time=0.013..0.014 rows=6 loops=2)
--                ->  Hash  (cost=1.12..1.12 rows=1 width=5) (actual time=0.022..0.023 rows=0 loops=1)
--                      Buckets: 1024  Batches: 1  Memory Usage: 8kB
--                      ->  Seq Scan on a  (cost=0.00..1.12 rows=1 width=5) (actual time=0.022..0.022 rows=0 loops=1)
--                            Filter: (y = 2)
--                            Rows Removed by Filter: 110
--  Planning Time: 0.197 ms
--  Execution Time: 0.122 ms
-- (21 rows)

EXPLAIN (ANALYZE, COSTS ON)
SELECT count(*) FROM a,b WHERE a.x=b.x AND a.y = 2;
set switch_join.enable=off;

-- EXPLAIN (ANALYZE, COSTS ON)
-- SELECT count(*) FROM a,b WHERE a.x=b.x AND a.y = 2;
--                                                  QUERY PLAN
-- -------------------------------------------------------------------------------------------------------------
--  Aggregate  (cost=505.06..505.07 rows=1 width=8) (actual time=0.051..0.053 rows=1 loops=1)
--    ->  Hash Join  (cost=1.14..505.06 rows=1 width=0) (actual time=0.047..0.049 rows=0 loops=1)
--          Hash Cond: (b.x = a.x)
--          ->  Seq Scan on b  (cost=0.00..487.30 rows=4430 width=5) (actual time=0.020..0.020 rows=1 loops=1)
--          ->  Hash  (cost=1.12..1.12 rows=1 width=5) (actual time=0.023..0.024 rows=0 loops=1)
--                Buckets: 1024  Batches: 1  Memory Usage: 8kB
--                ->  Seq Scan on a  (cost=0.00..1.12 rows=1 width=5) (actual time=0.022..0.022 rows=0 loops=1)
--                      Filter: (y = 2)
--                      Rows Removed by Filter: 110
--  Planning Time: 0.169 ms
--  Execution Time: 0.098 ms
-- (11 rows)