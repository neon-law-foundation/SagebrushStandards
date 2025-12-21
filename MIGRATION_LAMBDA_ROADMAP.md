# Standards Migration Lambda Implementation Roadmap

## Overview

This document outlines the complete implementation plan for deploying a Swift-based Lambda function that runs Fluent migrations and seeds PostgreSQL databases across three AWS accounts (staging, production, neonlaw).

## Architecture

```
GitHub (NeonLawFoundation/Standards)
    ↓ (GitHub Actions + OIDC)
CodeCommit (Standards repository in each account)
    ↓ (CodeCommit trigger)
CodeBuild (Builds ARM64 Lambda zip)
    ↓ (Uploads to S3)
S3 (Lambda deployment artifacts)
    ↓ (Updates Lambda function)
Lambda (MigrationRunner)
    ↓ (Invoked by CodeBuild)
Aurora PostgreSQL (Runs migrations & seeds)
```

## Progress Tracker

### ✅ Phase 1: Foundation (COMPLETED)
- [x] Copy seed YAML files from Luxe to Standards
- [x] Add Yams and AWS Lambda Runtime dependencies to Package.swift
- [x] Create MigrationRunner executable target
- [x] Add Seeds directory as Package resource

### 🚧 Phase 2: Seeding Logic (IN PROGRESS)
- [ ] Add complete seed loading logic to StandardsDAL/DatabaseConfiguration.swift
  - Copy seed parsing from Luxe/Dali/DatabaseConfiguration.swift
  - Adapt model-specific insert functions for Standards models
  - Make `runSeeds` public and return count
  - Handle foreign key resolution for nested YAML references

### 📋 Phase 3: Local Testing with TDD
- [ ] Create Docker Compose file for local PostgreSQL
- [ ] Write integration tests for MigrationRunner
  - Test migrations run successfully
  - Test seeds load correctly
  - Test upsert behavior (lookup_fields)
  - Test foreign key resolution
- [ ] Test MigrationRunner locally against Docker PostgreSQL
- [ ] **COMMIT**: "Add seeding logic and local tests"

### 📋 Phase 4: AWS Infrastructure - CloudFormation Stacks
- [ ] Create CodeBuildStack.swift in AWS repo
  - Buildspec for compiling Swift on Amazon Linux 2023
  - ARM64 architecture (Graviton)
  - Docker build environment
  - S3 artifact upload
  - Lambda function update
  - Manual Lambda invocation step
- [ ] Create GitHubOIDCStack.swift in AWS repo
  - OIDC identity provider
  - IAM role with trust policy for GitHub
  - Minimal permissions: codecommit:GitPush, codecommit:GitPull
- [ ] Update LambdaStack.swift or create MigrationLambdaStack.swift
  - VPC configuration (private subnets)
  - Security group allowing Aurora access
  - Secrets Manager permissions
  - Environment variables from Aurora stack outputs
- [ ] Write LocalStack tests for all stacks
  - Test stack creation
  - Test outputs are correct
  - Test IAM permissions
- [ ] **COMMIT**: "Add CloudFormation stacks with LocalStack tests"

### 📋 Phase 5: Deploy Infrastructure to AWS

#### 5.1: Deploy OIDC and CodeCommit
```bash
# Deploy OIDC provider to staging account
ENV=production swift run AWS create-github-oidc \
  --account 889786867297 \
  --region us-west-2 \
  --stack-name GitHubOIDC \
  --repository NeonLawFoundation/Standards

# Create CodeCommit repositories
ENV=production swift run AWS create-codecommit \
  --account 889786867297 \
  --region us-west-2 \
  --stack-name Standards \
  --repository-name Standards

# Repeat for production (978489150794) and neonlaw (102186460229)
```

#### 5.2: Deploy Aurora Databases
```bash
# Note: Currently blocked by IAM permissions
# Must update SagebrushCLIRole with Secrets Manager permissions first

# Staging
ENV=production swift run AWS create-aurora-postgres \
  --account 889786867297 \
  --region us-west-2 \
  --stack-name staging-aurora-postgres \
  --vpc-stack oregon-vpc \
  --db-name app \
  --min-capacity 0.5 \
  --max-capacity 1

# Production
ENV=production swift run AWS create-aurora-postgres \
  --account 978489150794 \
  --region us-west-2 \
  --stack-name production-aurora-postgres \
  --vpc-stack oregon-vpc \
  --db-name app \
  --min-capacity 0.5 \
  --max-capacity 1

# NeonLaw
ENV=production swift run AWS create-aurora-postgres \
  --account 102186460229 \
  --region us-west-2 \
  --stack-name neonlaw-aurora-postgres \
  --vpc-stack oregon-vpc \
  --db-name app \
  --min-capacity 0.5 \
  --max-capacity 1
```

#### 5.3: Deploy S3, CodeBuild, and Lambda
```bash
# For each account, deploy in order:

# 1. S3 bucket for Lambda artifacts
ENV=production swift run AWS create-s3 \
  --account ACCOUNT_ID \
  --region us-west-2 \
  --stack-name standards-lambda-artifacts \
  --bucket-name standards-lambda-artifacts-ACCOUNT_ID

# 2. Lambda function
ENV=production swift run AWS create-migration-lambda \
  --account ACCOUNT_ID \
  --region us-west-2 \
  --stack-name standards-migration-lambda \
  --vpc-stack oregon-vpc \
  --aurora-stack ACCOUNT-aurora-postgres \
  --s3-stack standards-lambda-artifacts

# 3. CodeBuild project
ENV=production swift run AWS create-codebuild \
  --account ACCOUNT_ID \
  --region us-west-2 \
  --stack-name standards-codebuild \
  --codecommit-repo Standards \
  --s3-stack standards-lambda-artifacts \
  --lambda-stack standards-migration-lambda
```

### 📋 Phase 6: GitHub Actions Workflows

#### 6.1: Staging (Push to main)
Create `.github/workflows/deploy-staging.yaml`:
```yaml
name: Deploy to Staging

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::889786867297:role/GitHubActionsCodeCommitRole
          aws-region: us-west-2

      - name: Push to CodeCommit Staging
        run: |
          git remote add staging codecommit://Standards
          git push staging main
```

#### 6.2: Production & NeonLaw (Tagged releases)
Create `.github/workflows/deploy-production.yaml`:
```yaml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*.*.*'

permissions:
  id-token: write
  contents: read

jobs:
  deploy-production:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::978489150794:role/GitHubActionsCodeCommitRole
          aws-region: us-west-2

      - name: Push to CodeCommit Production
        run: |
          git remote add production codecommit://Standards
          git push production ${{ github.ref_name }}

  deploy-neonlaw:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::102186460229:role/GitHubActionsCodeCommitRole
          aws-region: us-west-2

      - name: Push to CodeCommit NeonLaw
        run: |
          git remote add neonlaw codecommit://Standards
          git push neonlaw ${{ github.ref_name }}
```

### 📋 Phase 7: End-to-End Testing
- [ ] Test staging deployment:
  1. Push to main branch
  2. Verify GitHub Actions runs
  3. Verify CodeCommit receives push
  4. Verify CodeBuild builds Lambda
  5. Verify Lambda is updated
  6. Verify migrations run
  7. Verify seeds load
  8. Query Aurora to confirm data
- [ ] Test production deployment:
  1. Create and push git tag
  2. Verify both production and neonlaw get updated
- [ ] **COMMIT**: "Complete GitHub Actions workflows"

### 📋 Phase 8: Documentation
- [ ] Update Standards README.md with:
  - Lambda migration system overview
  - Local development with Docker PostgreSQL
  - Deployment process
  - Troubleshooting guide
- [ ] **COMMIT**: "Add migration Lambda documentation"

## Key Design Decisions

### 1. OIDC vs IAM Users
**Decision**: Use OIDC with GitHub Actions
- **Why**: No long-lived credentials, more secure, modern best practice
- **Permissions**: Only `codecommit:GitPush` and `codecommit:GitPull`

### 2. Lambda Architecture
**Decision**: ARM64 (Graviton)
- **Why**: Better price/performance, matches ScheduledReporting pattern
- **Runtime**: `provided.al2023` (custom Swift runtime)

### 3. Database Credentials
**Decision**: AWS Secrets Manager with cross-account access
- **Why**: Auto-generated passwords, rotation support, secure
- **Access**: Housekeeping account can read secrets from other accounts

### 4. Migration Trigger
**Decision**: Manual invocation in CodeBuild buildspec
- **Why**: Explicit control, visible in build logs, fail-fast on errors

### 5. Seed Data Format
**Decision**: YAML files with lookup_fields for upsert
- **Why**: Human-readable, matches existing Luxe pattern, supports nested references

## Testing Strategy

### Local Testing
1. **Unit Tests**: Test YAML parsing, model insertion logic
2. **Integration Tests**: Test against Docker PostgreSQL
3. **LocalStack Tests**: Test CloudFormation stack creation

### AWS Testing (Staging First)
1. Deploy to staging account first
2. Run manual tests
3. Verify in Aurora console
4. Only deploy to production/neonlaw after staging success

## Rollback Plan

If migration fails:
1. Lambda logs available in CloudWatch
2. Aurora snapshot taken before migration (7-day retention)
3. Can restore from snapshot if needed
4. Can revert CodeCommit to previous commit

## Security Considerations

1. **Network Isolation**: Lambda runs in VPC private subnets
2. **Database Access**: Security groups limit access to VPC only
3. **Credentials**: Never in code, always in Secrets Manager
4. **IAM**: Least privilege - GitHub can only push to CodeCommit
5. **Encryption**: Aurora encrypted at rest, Secrets Manager encrypted

## Open Questions

1. ~~Should we deploy Aurora databases now or wait?~~ → Deploy as part of Phase 5
2. ~~Do we need separate buildspec files for staging vs production?~~ → No, same buildspec
3. Should migrations be reversible (down migrations)? → Nice-to-have, not required for MVP

## Next Steps

I'm currently at **Phase 2: Seeding Logic**. The next action is to add the complete seed loading implementation to DatabaseConfiguration.swift.

Should I continue with this implementation plan, or would you like to adjust the approach?
