DROP TABLE IF EXISTS a,b CASCADE;
CREATE TABLE a WITH (autovacuum_enabled = false) AS
  SELECT gs % 10 AS x, gs as y FROM generate_series(1,1E1) AS gs;
CREATE TABLE b WITH (autovacuum_enabled = false) AS
  SELECT gs AS x FROM generate_series(1,1E1) AS gs;

-- It is most easy way to emulate optimizer error ...
ANALYZE a,b;
INSERT INTO a SELECT gs%5 AS gs, gs%5 as y FROM generate_series(1,1E6) AS gs;
INSERT INTO b SELECT 1 AS x FROM generate_series(1,1E3) AS gs;

EXPLAIN (ANALYZE, COSTS ON)
SELECT count(*) FROM a,b WHERE a.x=b.x AND a.y = 2;
--                                                    QUERY PLAN
-- ----------------------------------------------------------------------------------------------------------------
--  Aggregate  (cost=5866.25..5866.26 rows=1 width=8) (actual time=22503.042..22503.043 rows=1 loops=1)
--    ->  Nested Loop  (cost=0.00..5866.25 rows=1 width=0) (actual time=0.053..22489.535 rows=200001 loops=1)
--          Join Filter: (a.x = b.x)
--          Rows Removed by Join Filter: 201801009
--          ->  Seq Scan on a  (cost=0.00..5860.12 rows=1 width=4) (actual time=0.032..91.160 rows=200001 loops=1)
--                Filter: (y = '2'::numeric)
--                Rows Removed by Filter: 800009
--          ->  Seq Scan on b  (cost=0.00..5.50 rows=50 width=5) (actual time=0.002..0.040 rows=1010 loops=200001)
--  Planning Time: 7.454 ms
--  Execution Time: 22503.106 ms
-- (10 rows)

set switch_join.enable=on;

EXPLAIN (ANALYZE, COSTS ON)
SELECT count(*) FROM a,b WHERE a.x=b.x AND a.y = 2;
--                                                          QUERY PLAN

-- ---------------------------------------------------------------------------------------------------------------------
-- -------
--  Aggregate  (cost=5872.51..5872.52 rows=1 width=8) (actual time=120.037..120.041 rows=1 loops=1)
--    ->  Custom Scan (SwitchJoin)  (cost=6.12..5872.50 rows=1 width=0) (actual time=0.609..113.868 rows=200001 loops=1)
--          --> Limit cardinality: 10
--          ->  Nested Loop  (cost=0.00..5866.38 rows=1 width=0) (never executed)
--                Join Filter: (a.x = b.x)
--                ->  Materialize  (cost=0.00..5.75 rows=50 width=5) (actual time=0.019..0.172 rows=510 loops=2)
--                      ->  Seq Scan on b  (cost=0.00..5.50 rows=50 width=5) (actual time=0.018..0.087 rows=510 loops=2)
--                ->  Materialize  (cost=0.00..5860.13 rows=1 width=4) (never executed)
--                      ->  Seq Scan on a  (cost=0.00..5860.12 rows=1 width=4) (never executed)
--                            Filter: (y = '2'::numeric)
--          ->  Hash Join  (cost=6.12..5866.26 rows=1 width=0) (actual time=0.572..105.670 rows=200001 loops=1)
--                Hash Cond: (a.x = b.x)
--                ->  Seq Scan on a  (cost=0.00..5860.12 rows=1 width=4) (actual time=0.018..77.827 rows=200001 loops=1)
--                      Filter: (y = '2'::numeric)
--                      Rows Removed by Filter: 800009
--                ->  Hash  (cost=5.75..5.75 rows=50 width=5) (actual time=0.547..0.547 rows=1010 loops=1)
--                      Buckets: 1024  Batches: 1  Memory Usage: 45kB
--                      ->  Materialize  (cost=0.00..5.75 rows=50 width=5) (actual time=0.019..0.172 rows=510 loops=2)
--                            ->  Seq Scan on b  (cost=0.00..5.50 rows=50 width=5) (actual time=0.018..0.087 rows=510 loops=2)
--  Planning Time: 0.229 ms
--  Execution Time: 120.102 ms
-- (21 rows)

