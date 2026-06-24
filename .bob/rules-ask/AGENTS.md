# Ask Mode Rules (Non-Obvious Only)

## Project Organization

- Two independent components with no shared dependencies:
  - `infraestructura/` - Terraform for AWS (S3→SQS→Lambda)
  - `snowflake-seeder/` - Python script for Snowflake database seeding

## Non-Obvious Documentation Context

### Terraform Infrastructure
- Must be deployed from `infraestructura/` directory, not project root
- Creates event-driven pipeline: S3 object creation → SQS → Lambda → S3 copy
- Lambda function code is in `infraestructura/lambda/lambda_function.py`
- S3 bucket naming constraint: no underscores allowed (AWS restriction)

### Snowflake Seeder
- Credentials loaded from environment variables (not config files)
- Uses custom utilities in `utils/` for name/date generation
- Has multiple bugs that need fixing (see code mode rules)
- No database connection pooling - creates new connection each run

### Architecture Decisions
- SQS visibility timeout (180s) is 3x Lambda timeout (60s) - intentional for retry logic
- Lambda uses `copy_object()` API instead of get+put for efficiency
- No error handling in seeder.py - will fail silently on connection issues