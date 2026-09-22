-- useful_queries.sql
-- Postgres 14+. Operational queries I run when a database feels sick.
-- Nothing here writes data except the clearly-marked kill/cancel section at
-- the bottom. Read before you paste.
--
-- Tested on Postgres 15. Some views (pg_stat_statements) need the extension.

-- ---------------------------------------------------------------------------
-- 1. Biggest tables and indexes
-- ---------------------------------------------------------------------------
SELECT
  schemaname || '.' || relname              AS table,
  pg_size_pretty(pg_total_relation_size(relid))   AS total,
  pg_size_pretty(pg_relation_size(relid))         AS table_only,
  pg_size_pretty(pg_indexes_size(relid))          AS indexes
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 20;

-- Index bloat proxy: indexes bigger than the table are a smell.
SELECT
  relname AS table,
  pg_size_pretty(pg_relation_size(relid))  AS table_size,
  pg_size_pretty(pg_indexes_size(relid))   AS index_size
FROM pg_catalog.pg_statio_user_tables
WHERE pg_indexes_size(relid) > pg_relation_size(relid)
ORDER BY pg_indexes_size(relid) DESC;

-- ---------------------------------------------------------------------------
-- 2. Long-running and blocked queries
-- ---------------------------------------------------------------------------
-- Anything running longer than a minute right now.
SELECT
  pid,
  now() - query_start                     AS running_for,
  state,
  wait_event_type,
  left(query, 80)                         AS query
FROM pg_stat_activity
WHERE state <> 'idle'
  AND now() - query_start > interval '1 minute'
ORDER BY running_for DESC;

-- Blocked queries and who is blocking them. The join is the ugly-but-correct
-- way to do it; pg_blocking_pids() is simpler if you're on 9.6+.
SELECT
  blocked.pid                              AS blocked_pid,
  blocked.query                            AS blocked_query,
  pg_blocking_pids(blocked.pid)            AS blocking_pids
FROM pg_stat_activity blocked
WHERE cardinality(pg_blocking_pids(blocked.pid)) > 0;

-- Idle in transaction is the classic connection hog. Investigate these.
SELECT pid, state, now() - state_change AS idle_for, left(query, 60)
FROM pg_stat_activity
WHERE state = 'idle in transaction'
ORDER BY idle_for DESC;

-- ---------------------------------------------------------------------------
-- 3. Connection usage
-- ---------------------------------------------------------------------------
SELECT
  (SELECT count(*) FROM pg_stat_activity) AS used,
  current_setting('max_connections')::int AS max,
  round(100.0 * (SELECT count(*) FROM pg_stat_activity)
        / current_setting('max_connections')::int, 1) AS pct_used;

-- Connections grouped by application/user, useful for finding a leaking pool.
SELECT usename, application_name, count(*)
FROM pg_stat_activity
GROUP BY 1, 2
ORDER BY 3 DESC;

-- ---------------------------------------------------------------------------
-- 4. Table health: dead tuples, vacuum freshness
-- ---------------------------------------------------------------------------
SELECT
  relname,
  n_live_tup,
  n_dead_tup,
  round(100.0 * n_dead_tup / greatest(n_live_tup + n_dead_tup, 1), 1) AS dead_pct,
  last_autovacuum,
  last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 20;

-- ---------------------------------------------------------------------------
-- 5. Slow statements (requires: CREATE EXTENSION pg_stat_statements;)
-- ---------------------------------------------------------------------------
SELECT
  calls,
  round(total_exec_time::numeric, 1)  AS total_ms,
  round(mean_exec_time::numeric, 2)   AS mean_ms,
  rows,
  left(query, 80)                     AS query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- ---------------------------------------------------------------------------
-- 6. Cache hit ratio (want > 0.99 for an OLTP db)
-- ---------------------------------------------------------------------------
SELECT
  round(sum(blks_hit) * 100.0 / nullif(sum(blks_hit + blks_read), 0), 2)
    AS cache_hit_pct
FROM pg_stat_database;

-- ---------------------------------------------------------------------------
-- 7. Dangerous section. These terminate other sessions.
-- ---------------------------------------------------------------------------
-- Kill a specific query (cancels it, keeps the connection):
--   SELECT pg_cancel_backend(12345);
-- Kill the whole session (like kill -9):
--   SELECT pg_terminate_backend(12345);
--
-- Kill every idle-in-transaction session older than 10 minutes. I run this on
-- a staging box; think hard before running it in prod.
--   SELECT pg_terminate_backend(pid)
--   FROM pg_stat_activity
--   WHERE state = 'idle in transaction'
--     AND state_change < now() - interval '10 minutes'
--     AND pid <> pg_backend_pid();
