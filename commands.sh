#!/bin/bash
set -e

# 1. Create custom network if it does not exist
docker network inspect app-net >/dev/null 2>&1 || docker network create app-net

# 2. Create named volume if it does not exist
docker volume inspect db-data >/dev/null 2>&1 || docker volume create db-data

# 3. Recreate PostgreSQL container, preserving db-data
docker rm -f db-server 2>/dev/null || true

docker run -d \
  --name db-server \
  --network app-net \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=apppass123 \
  -e POSTGRES_DB=appdb \
  -v db-data:/var/lib/postgresql/data \
  postgres:15-alpine

# 4. Recreate backend network test container
docker rm -f app-container 2>/dev/null || true

docker run -d \
  --name app-container \
  --network app-net \
  -e DB_HOST=db-server \
  -e DB_PORT=5432 \
  -e DB_NAME=appdb \
  -e DB_USER=appuser \
  -e DB_PASSWORD=apppass123 \
  alpine:3.20 \
  sh -c "while true; do sleep 3600; done"

# 5. Verify DNS resolution
docker exec app-container ping -c 2 db-server