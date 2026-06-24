# Ask Mode Rules (Non-Obvious Only)

## Project Organization

- Two independent components with no shared dependencies:
  - `infraestructura/` - Terraform for AWS (S3→SQS→Lambda)
  - `snowflake-seeder/` - Python script for Snowflake database seeding

## Non-Obvious Documentation Context

### Terraform Infrastructure
- Must be deployed from `infraestructura/` directory, not project root
- Creates event-driven pipeline: S3 object creation → SQS → Lambda → S3 copy
- Lambda function code is in `infraestructura/lambda/lambda_function.py`; Terraform zips it automatically
- S3 bucket naming constraint: no underscores allowed (AWS restriction)
- Two required tfvars with no defaults: `storage_aws_iam_user_arn`, `storage_aws_external_id` — see `env/test.tfvars`

### Snowflake Seeder
- Credentials loaded from environment variables (not config files); `get_credentials()` returns `None` silently for missing vars
- Validates all 7 credentials before attempting connection
- Uses custom utilities in `utils/` for name/date generation (static word lists, no external libs)
- No database connection pooling — creates new connection each run
- Tests in `test/` directory; `conftest.py` patches `sys.path` so `utils/` imports resolve

### Architecture Decisions
- SQS visibility timeout (180s) is 3x Lambda timeout (60s) — intentional for retry logic
- Lambda uses `copy_object()` API instead of get+put for efficiency
- Lambda event is double-nested: SQS wraps a JSON-encoded S3 event
