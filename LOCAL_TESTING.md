# Local Testing Guide

This guide explains how to test the Standards migration and seeding system locally before deploying to AWS.

## Overview

The Standards package includes comprehensive integration tests that verify:

- Database migrations run successfully
- Seeds load correctly from YAML files
- Upsert behavior works (lookup_fields)
- Foreign key resolution works (nested YAML references)
- Idempotent seed loading (can run multiple times)

## Prerequisites

- Swift 6.2 or later
- Docker and Docker Compose (for PostgreSQL testing)

## Quick Start

### 1. Run Tests with SQLite (In-Memory)

The fastest way to run tests is with SQLite in-memory databases:

```bash
swift test
```

This runs all tests including:

- `MigrationIntegrationTests` - Comprehensive tests with SQLite
- `PostgresIntegrationTests` - Skipped unless PostgreSQL is available

### 2. Run Tests with PostgreSQL (Docker)

To test against a real PostgreSQL database (matching AWS Aurora):

```bash
# Option A: Use the provided script (recommended)
./scripts/test-local-postgres.sh

# Option B: Manual setup
docker-compose up -d
ENV=production \
DATABASE_HOST=localhost \
DATABASE_PORT=5432 \
DATABASE_USERNAME=postgres \
DATABASE_PASSWORD=postgres \
DATABASE_NAME=standards_test \
swift test --filter PostgresIntegrationTests
docker-compose down
```

## Test Suites

### MigrationIntegrationTests

Fast tests using SQLite in-memory databases. These tests verify:

- ✅ Database migrations create correct schema
- ✅ All tables exist after migrations
- ✅ Seeds load from YAML files
- ✅ Seeds load in correct order (respecting foreign key dependencies)
- ✅ Upsert creates new records when they don't exist
- ✅ Upsert updates existing records when found
- ✅ Upsert works with multiple lookup fields
- ✅ Foreign keys resolve via nested YAML references
- ✅ Person with nested address relationships
- ✅ All seed models load without errors
- ✅ Idempotent seed loading (can run seeds multiple times)

Example:

```bash
swift test --filter MigrationIntegrationTests
```

### PostgresIntegrationTests

Tests against real PostgreSQL database. These tests verify:

- ✅ MigrationRunner works against real PostgreSQL
- ✅ Seeds load correctly in PostgreSQL
- ✅ Data integrity in production-like environment

Example:

```bash
ENV=production DATABASE_HOST=localhost swift test --filter PostgresIntegrationTests
```

## Docker Compose Configuration

The `docker-compose.yml` file provides a local PostgreSQL database that matches the AWS Aurora configuration:

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: standards-postgres-test
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: standards_test
    ports:
      - "5432:5432"
```

## Environment Variables

The tests use these environment variables to configure database connections:

- `ENV` - Environment (testing, development, production)
  - `testing` = SQLite in-memory
  - `development` = SQLite file-based
  - `production` = PostgreSQL
- `DATABASE_HOST` - PostgreSQL host (default: localhost)
- `DATABASE_PORT` - PostgreSQL port (default: 5432)
- `DATABASE_USERNAME` - PostgreSQL username (default: postgres)
- `DATABASE_PASSWORD` - PostgreSQL password (default: empty)
- `DATABASE_NAME` - PostgreSQL database name (default: standards)

## Seed Files

Seeds are loaded from YAML files in `Sources/StandardsDAL/Seeds/`:

- `Jurisdiction.yaml` - 52 jurisdictions
- `EntityType.yaml` - 10 entity types
- `Question.yaml` - 22 questions
- `Person.yaml` - 14 people
- `User.yaml` - 8 users
- `Entity.yaml` - 12 entities
- `Credential.yaml` - 5 credentials
- `Address.yaml` - 6 addresses
- `Mailbox.yaml` - 3 mailboxes
- `PersonEntityRole.yaml` - 9 person-entity relationships

Total: **141 seed records**

## Testing MigrationRunner Locally

To test the Lambda function locally:

```bash
# Build the MigrationRunner
swift build -c release --product MigrationRunner

# Start PostgreSQL
docker-compose up -d

# Set environment variables
export ENV=production
export DATABASE_HOST=localhost
export DATABASE_PORT=5432
export DATABASE_USERNAME=postgres
export DATABASE_PASSWORD=postgres
export DATABASE_NAME=standards_test

# The MigrationRunner is designed to run as an AWS Lambda function
# For local testing, use the integration tests instead
swift test --filter PostgresIntegrationTests

# Clean up
docker-compose down
```

## Troubleshooting

### PostgreSQL Connection Failed

If you see connection errors:

```bash
# Check if PostgreSQL is running
docker ps | grep standards-postgres-test

# Check PostgreSQL logs
docker logs standards-postgres-test

# Restart PostgreSQL
docker-compose down
docker-compose up -d
```

### Seed Files Not Found

If seeds fail to load:

```bash
# Verify seed files exist
ls -la Sources/StandardsDAL/Seeds/

# Build the package to copy resources
swift build
```

### Tests Hang or Timeout

If tests hang:

```bash
# Check for zombie processes
ps aux | grep swift

# Kill hung tests
pkill -9 swift-testing

# Restart Docker
docker-compose down
docker-compose up -d
```

## Next Steps

After local testing succeeds:

1. Commit changes to git
2. Push to `main` branch
3. GitHub Actions will deploy to staging
4. Monitor CodeBuild and Lambda logs
5. Verify seeds loaded in Aurora
