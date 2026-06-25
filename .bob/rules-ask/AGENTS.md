# Ask Mode Rules (Non-Obvious Only)

## Project Organization

- Two deployable components with no shared dependencies:
  - `infraestructura/` - Terraform for AWS (S3→SQS→Lambda)
  - `snowflake-integration/` - Python script for Snowflake database seeding + S3 integration DDL

## Non-Obvious Documentation Context

### Terraform Infrastructure
- Must be deployed from `infraestructura/` directory, not project root
- Creates event-driven pipeline: S3 object creation → SQS → Lambda → S3 copy
- Lambda function code is in `infraestructura/lambda/lambda_function.py`; Terraform zips it automatically
- S3 bucket naming constraint: no underscores allowed (AWS restriction)
- Two required tfvars with no defaults: `storage_aws_iam_user_arn`, `storage_aws_external_id` — see `env/test.tfvars`
- Terraform native tests in `infraestructura/tests/main.tftest.hcl` use `command = plan` only

### Snowflake Integration
- Credentials loaded from environment variables (not config files); `get_credentials()` returns `None` silently for missing vars
- Validates all 7 credentials before attempting connection
- Uses custom utilities in `utils/` for name/date generation (static word lists, no external libs)
- No database connection pooling — creates new connection each run
- Tests in `test/` directory; `conftest.py` patches `sys.path` so `utils/` imports resolve
- `integration.sql` is manual Snowflake DDL for S3 external stage setup — not executed by the seeder
- Has a local `.venv` in `snowflake-integration/` directory

### Architecture Decisions
- SQS visibility timeout (180s) is 3x Lambda timeout (60s) — intentional for retry logic
- Lambda uses `copy_object()` API instead of get+put for efficiency
- Lambda event is double-nested: SQS wraps a JSON-encoded S3 event
- `prevent_destroy` lifecycle meta-argument cannot be asserted in Terraform test blocks
