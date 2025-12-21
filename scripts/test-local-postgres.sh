#!/bin/bash
set -euo pipefail

# Test MigrationRunner against local PostgreSQL
# This script starts PostgreSQL via docker-compose, runs tests, and cleans up

echo "🚀 Starting PostgreSQL..."
docker-compose up -d

echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 5

# Wait for PostgreSQL to accept connections
until docker exec standards-postgres-test pg_isready -U postgres > /dev/null 2>&1; do
  echo "   PostgreSQL is unavailable - sleeping"
  sleep 2
done

echo "✅ PostgreSQL is ready!"

echo ""
echo "🧪 Running integration tests against PostgreSQL..."
ENV=production \
DATABASE_HOST=localhost \
DATABASE_PORT=5432 \
DATABASE_USERNAME=postgres \
DATABASE_PASSWORD=postgres \
DATABASE_NAME=standards_test \
swift test --filter PostgresIntegrationTests

echo ""
echo "🧹 Cleaning up..."
docker-compose down

echo ""
echo "✨ All tests passed!"
