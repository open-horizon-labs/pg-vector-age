# syntax=docker/dockerfile:1
# pg-vector-age: PostgreSQL 18 + pgvector 0.8.2 + Apache AGE 1.7.0 + Citus 14 + FTS
# Multi-arch: linux/amd64 + linux/arm64

ARG PG_MAJOR=18
ARG PGVECTOR_VERSION=0.8.2
ARG AGE_TAG=PG18/v1.7.0-rc0
ARG CITUS_VERSION=14.0.0

# ── builder ────────────────────────────────────────────────────────────────────
FROM postgres:${PG_MAJOR}-bookworm AS builder

ARG PG_MAJOR
ARG PGVECTOR_VERSION
ARG AGE_TAG
ARG CITUS_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    wget \
    ca-certificates \
    libreadline-dev \
    zlib1g-dev \
    flex \
    bison \
    libssl-dev \
    libkrb5-dev \
    libcurl4-openssl-dev \
    postgresql-server-dev-${PG_MAJOR} \
    && rm -rf /var/lib/apt/lists/*

# pgvector
RUN wget -qO /tmp/pgvector.tar.gz \
      "https://github.com/pgvector/pgvector/archive/refs/tags/v${PGVECTOR_VERSION}.tar.gz" \
    && tar -xzf /tmp/pgvector.tar.gz -C /tmp \
    && cd /tmp/pgvector-${PGVECTOR_VERSION} \
    && make PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config \
    && make install PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config

# Apache AGE
RUN wget -qO /tmp/age.tar.gz \
      "https://github.com/apache/age/archive/refs/tags/${AGE_TAG}.tar.gz" \
    && tar -xzf /tmp/age.tar.gz -C /tmp \
    && cd /tmp/age-* \
    && make PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config \
    && make install PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config

# Citus
RUN wget -qO /tmp/citus.tar.gz \
      "https://github.com/citusdata/citus/archive/refs/tags/v${CITUS_VERSION}.tar.gz" \
    && tar -xzf /tmp/citus.tar.gz -C /tmp \
    && cd /tmp/citus-${CITUS_VERSION} \
    && ./configure PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config \
    && make \
    && make install

# ── runtime ────────────────────────────────────────────────────────────────────
FROM postgres:${PG_MAJOR}-bookworm

ARG PG_MAJOR

# Runtime deps for Citus (libcurl, libkrb5) — AGE and pgvector have none
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4 \
    libkrb5-3 \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled extensions from builder
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/       /usr/lib/postgresql/${PG_MAJOR}/lib/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/ /usr/share/postgresql/${PG_MAJOR}/extension/

# Init scripts (alphabetical order = execution order)
COPY initdb/ /docker-entrypoint-initdb.d/

# TLS cert generation entrypoint wrapper
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
CMD ["postgres"]
