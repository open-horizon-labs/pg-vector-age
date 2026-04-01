-- pg-vector-age: enable extensions
-- Runs after 00-configure.sh restarts the temp server with shared_preload_libraries loaded.

CREATE EXTENSION IF NOT EXISTS citus;
CREATE EXTENSION IF NOT EXISTS age;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;     -- FTS: GIN index support for composite queries
CREATE EXTENSION IF NOT EXISTS unaccent;      -- FTS: accent-insensitive search

-- Make AGE catalog visible by default for sessions in this database
ALTER DATABASE postgres SET search_path = ag_catalog, "$user", public;
