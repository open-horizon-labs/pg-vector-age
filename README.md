# pg-vector-age

PostgreSQL 18 with pgvector, Apache AGE, Citus, and full-text search extensions — pre-configured, multi-arch, production-hardened.

## What's inside

| Component | Version | Purpose |
|-----------|---------|---------|
| PostgreSQL | 18 | Base |
| [pgvector](https://github.com/pgvector/pgvector) | 0.8.2 | Vector similarity search |
| [Apache AGE](https://age.apache.org/) | 1.7.0 | Graph queries (openCypher) |
| [Citus](https://www.citusdata.com/) | 14 | Distributed / columnar |
| pg_trgm | built-in | Trigram similarity + FTS indexes |
| unaccent | built-in | Accent-insensitive text search |
| btree_gin | built-in | Composite GIN indexes |

**Platform:** `linux/amd64` + `linux/arm64` (native on Apple M-series, AWS Graviton)

## Hardening

- **scram-sha-256** — no `trust` or `md5`
- **TLS** — self-signed cert auto-generated on first start; mount your own at `/var/lib/postgresql/tls/`
- **Audit logging** — connections, disconnections, DDL (`log_statement = 'ddl'`)
- **Minimal attack surface** — multi-stage build; no build tools in runtime image

## Quick start

```bash
# docker-compose
cp docker-compose.example.yml docker-compose.yml
POSTGRES_PASSWORD=secret docker compose up -d

# connect
psql "host=localhost port=5432 dbname=app user=app sslmode=require"
```

## Extensions

All extensions are created in the default database on first start:

```sql
-- vector similarity
SELECT '[1,2,3]'::vector <=> '[1,2,4]'::vector;

-- graph (openCypher via AGE)
SELECT * FROM ag_catalog.cypher('my_graph', $$
  CREATE (n:Person {name: 'Alice'}) RETURN n
$$) AS (n agtype);

-- full-text search
SELECT to_tsvector('english', 'The quick brown fox') @@
       to_tsquery('english', 'quick & fox');

-- trigram similarity
SELECT similarity('hello', 'helo');

-- Citus distributed table
SELECT create_distributed_table('my_table', 'tenant_id');
```

## Custom init SQL

Mount additional init scripts:

```yaml
volumes:
  - ./my-init.sql:/docker-entrypoint-initdb.d/02-my-init.sql
```

## Bring your own TLS

```yaml
volumes:
  - ./certs/server.crt:/var/lib/postgresql/tls/server.crt:ro
  - ./certs/server.key:/var/lib/postgresql/tls/server.key:ro
```

## Build locally

```bash
docker build -t pg-vector-age .
```

## License

Apache 2.0
