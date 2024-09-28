delete from a;
EXPLAIN (ANALYZE, COSTS ON)
SELECT count(*) FROM a,b WHERE a.x=b.x AND a.y = 2;

--                                                           QUERY PLAN
-- -------------------------------------------------------------------------------------------------------------------------------
--  Aggregate  (cost=5272.48..5272.49 rows=1 width=8) (actual time=5.089..5.094 rows=1 loops=1)
--    ->  Custom Scan (SwitchJoin)  (cost=27.73..5271.98 rows=200 width=0) (actual time=5.084..5.088 rows=0 loops=1)
--          --> Limit cardinality: 400
--          ->  Nested Loop  (cost=0.00..5244.25 rows=200 width=0) (never executed)
--                Join Filter: (a.x = b.x)
--                ->  Materialize  (cost=0.00..20.15 rows=1010 width=5) (actual time=0.021..0.142 rows=400 loops=1)
--                      ->  Seq Scan on b  (cost=0.00..15.10 rows=1010 width=5) (actual time=0.020..0.076 rows=400 loops=1)
--                ->  Materialize  (cost=0.00..5214.01 rows=1 width=4) (never executed)
--                      ->  Seq Scan on a  (cost=0.00..5214.00 rows=1 width=4) (never executed)
--                            Filter: (y = '2'::numeric)
--          ->  Hash Join  (cost=27.73..5244.98 rows=200 width=0) (actual time=4.914..4.916 rows=0 loops=1)
--                Hash Cond: (a.x = b.x)
--                ->  Seq Scan on a  (cost=0.00..5214.00 rows=1 width=4) (actual time=4.912..4.913 rows=0 loops=1)
--                      Filter: (y = '2'::numeric)
--                ->  Hash  (cost=20.15..20.15 rows=1010 width=5) (never executed)
--                      ->  Materialize  (cost=0.00..20.15 rows=1010 width=5) (actual time=0.021..0.142 rows=400 loops=1)
--                            ->  Seq Scan on b  (cost=0.00..15.10 rows=1010 width=5) (actual time=0.020..0.076 rows=400 loops=1)
--  Planning Time: 0.217 ms
--  Execution Time: 5.147 ms
-- (19 rows)
set switch_join.enable=off;
 EXPLAIN (ANALYZE, COSTS ON)
 SELECT count(*) FROM a,b WHERE a.x=b.x AND a.y = 2;
--                                                 QUERY PLAN
-- ----------------------------------------------------------------------------------------------------------
--  Aggregate  (cost=5242.23..5242.24 rows=1 width=8) (actual time=4.734..4.735 rows=1 loops=1)
--    ->  Nested Loop  (cost=0.00..5241.73 rows=200 width=0) (actual time=4.729..4.731 rows=0 loops=1)
--          Join Filter: (a.x = b.x)
--          ->  Seq Scan on a  (cost=0.00..5214.00 rows=1 width=4) (actual time=4.729..4.730 rows=0 loops=1)
--                Filter: (y = '2'::numeric)
--          ->  Seq Scan on b  (cost=0.00..15.10 rows=1010 width=5) (never executed)
--  Planning Time: 0.188 ms
--  Execution Time: 4.765 ms
-- (8 rows)

