# Sagebrush Standards

Questionnaires, Workflows, and Templates together to create computable
contracts.

## Installation

### Via Homebrew (Recommended)

```bash
# Add the tap
brew tap neon-law-foundation/tap

# Install the Standards CLI
brew install standards
```

### Manual Installation

```bash
./install.sh
```

This installs the `standards` CLI to `~/.local/bin/standards`.

Make sure `~/.local/bin` is in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Commands

### `standards lint <directory> [--fix]`

Validates that all Markdown files (except README.md) have lines ≤120 characters.

```bash
# Check current directory
standards lint .

# Check specific directory
standards lint ShookFamily/Estate

# Auto-fix violations
standards lint . --fix
```

**Note:** README.md files are excluded from linting.

### `standards voice <directory>`

Checks Markdown files (except README.md) for active voice and tone compliance
according to the writing guidelines in
CLAUDE.md.

```bash
# Check current directory
standards voice .

# Check specific directory
standards voice ShookFamily/Estate
```

**Note:** README.md files are excluded from voice checking.

### `standards setup`

Creates the `~/Standards` directory structure and fetches all client files from
the Sagebrush API.

When you run this command, you receive all client files stored in AWS CodeCommit
repositories that you have access to. For example, if you're a member of the law
firm Neon Law, you will receive all client files stored in the Neon Law AWS
account.

**Important:** Sagebrush manages the AWS infrastructure and code repositories
for law firms, but cannot access the client data itself. Only lawyers with
proper credentials can access client files.

```bash
standards setup
```

### `standards sync`

Syncs all projects in `~/Standards` by running `git pull` on existing
repositories.

```bash
standards sync
```

### `standards pdf <file>`

Converts a standard Markdown file to PDF format. The command validates the file
first (same as `standards lint`), strips the YAML frontmatter, and generates a
PDF with:

- Standard American letter size (8.5 x 11 inches)
- 1-inch margins on all sides
- Professional typography

The PDF is created in the same directory as the input file with a `.pdf`
extension.

```bash
# Convert a standard to PDF
standards pdf nevada.md

# Output: nevada.pdf (in the same directory)
```

**Requirements:**

- Input file must be a valid standard with YAML frontmatter
- All lines must be ≤120 characters
- Must have a `title` field in frontmatter
- Requires `pandoc` to be installed: `brew install pandoc`

**Note:** If validation fails, the command will display detailed error messages
and refuse to generate the PDF until issues are fixed.

## Development

Run tests:

```bash
swift test
```

Build the project:

```bash
swift build
```

## Migration Lambda Deployment

### Architecture

```mermaid
graph TB
    subgraph GitHub
        Repo[Standards Repository]
    end

    subgraph GitHub Actions
        Staging[deploy-staging.yaml]
        Prod[deploy-production.yaml]
    end

    subgraph AWS Staging
        CC1[CodeCommit]
        EB1[EventBridge]
        CB1[CodeBuild]
        S3_1[S3 Artifacts]
        L1[Lambda]
        DB1[(Aurora PostgreSQL)]
    end

    subgraph AWS Production
        CC2[CodeCommit]
        EB2[EventBridge]
        CB2[CodeBuild]
        S3_2[S3 Artifacts]
        L2[Lambda]
        DB2[(Aurora PostgreSQL)]
    end

    subgraph AWS NeonLaw
        CC3[CodeCommit]
        EB3[EventBridge]
        CB3[CodeBuild]
        S3_3[S3 Artifacts]
        L3[Lambda]
        DB3[(Aurora PostgreSQL)]
    end

    Repo -->|push to main| Staging
    Repo -->|tag v*.*.*| Prod

    Staging -->|OIDC| CC1
    Prod -->|OIDC| CC2
    Prod -->|OIDC| CC3

    CC1 -->|trigger| EB1 -->|start| CB1
    CC2 -->|trigger| EB2 -->|start| CB2
    CC3 -->|trigger| EB3 -->|start| CB3

    CB1 -->|upload| S3_1 -->|update| L1 -->|migrate| DB1
    CB2 -->|upload| S3_2 -->|update| L2 -->|migrate| DB2
    CB3 -->|upload| S3_3 -->|update| L3 -->|migrate| DB3
```

### Deployment Workflows

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant GA as GitHub Actions
    participant CC as CodeCommit
    participant CB as CodeBuild
    participant S3 as S3
    participant Lambda as Lambda
    participant DB as Aurora

    Dev->>GH: git push origin main
    GH->>GA: Trigger deploy-staging
    GA->>GA: Assume OIDC role
    GA->>CC: Push code
    CC->>CB: EventBridge trigger
    CB->>CB: Install Swift 6.2.3
    CB->>CB: swift build -c release
    CB->>CB: Package lambda.zip
    CB->>S3: Upload artifact
    CB->>Lambda: Update function code
    CB->>Lambda: Invoke function
    Lambda->>DB: Run migrations
    Lambda->>DB: Load seeds
    DB-->>Lambda: Success
    Lambda-->>CB: Success
    CB-->>Dev: Build complete ✅
```

### Quick Deploy

**Staging (auto-deploy):**

```bash
git push origin main
```

**Production (manual tag):**

```bash
git tag v1.0.0
git push origin v1.0.0
```

### Monitoring

| Environment | GitHub Actions | CodeBuild | Lambda |
| ----------- | -------------- | --------- | ------ |
| **Staging** | [Workflow](https://github.com/neon-law-foundation/Standards/actions/workflows/deploy-staging.yaml) | [Project](https://us-west-2.console.aws.amazon.com/codesuite/codebuild/889786867297/projects/StandardsMigrationBuilder) | [Function](https://us-west-2.console.aws.amazon.com/lambda/home?region=us-west-2#/functions/MigrationRunner) |
| **Production** | [Workflow](https://github.com/neon-law-foundation/Standards/actions/workflows/deploy-production.yaml) | [Project](https://us-west-2.console.aws.amazon.com/codesuite/codebuild/978489150794/projects/StandardsMigrationBuilder) | Switch to account 978489150794 |
| **NeonLaw** | Same as Production | [Project](https://us-west-2.console.aws.amazon.com/codesuite/codebuild/102186460229/projects/StandardsMigrationBuilder) | Switch to account 102186460229 |

### Troubleshooting

**GitHub Actions fails (AccessDenied):**

```bash
# Check OIDC role exists
aws iam get-role --role-name GitHubActionsRole --profile sagebrush-staging
```

**CodeBuild doesn't start:**

```bash
# Check EventBridge rule
aws events list-rules --name-prefix CodeCommit --profile sagebrush-staging
```

**Swift version mismatch:**

- Update `buildspec.yml` SWIFT_VERSION to match `Package.swift` swift-tools-version
- Current: Swift 6.2.3

**Lambda can't connect to database:**

```bash
# Check Lambda logs
aws logs tail /aws/lambda/MigrationRunner --follow --profile sagebrush-staging
```

**Migrations fail:**

```sql
-- Check which migrations ran
SELECT * FROM fluent_migrations ORDER BY batch DESC;
```

### Rollback

**Lambda:**

```bash
# List versions
aws lambda list-versions-by-function --function-name MigrationRunner \
  --profile sagebrush-staging

# Use previous version from S3
aws lambda update-function-code --function-name MigrationRunner \
  --s3-bucket standards-lambda-artifacts-889786867297 \
  --s3-key lambda-TIMESTAMP.zip \
  --profile sagebrush-staging
```

**Database:**

```bash
# Restore from automatic snapshot (created before each migration)
aws rds describe-db-cluster-snapshots \
  --db-cluster-identifier staging-aurora-postgres \
  --profile sagebrush-staging
```

### Local Testing

```bash
# Start PostgreSQL
docker-compose up -d postgres

# Run migrations locally
swift run MigrationRunner

# Query results
psql -h localhost -U postgres -d app -c "SELECT * FROM fluent_migrations;"
```

---

For complete troubleshooting guide, see `DEPLOYMENT_GUIDE.md`.
