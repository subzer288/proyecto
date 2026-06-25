# Ask Mode Rules (Non-Obvious Only)

## Project Organization

- Two deployable components with no shared dependencies:
  - `infraestructura/` - Terraform for AWS (S3→SQS→Lambda)
  - `snowflake-integration/` - Python scripts for Snowflake database seeding and data pipeline

## Non-Obvious Documentation Context

### Terraform Infrastructure
- Must be deployed from `infraestructura/` directory, not project root
- Creates event-driven pipeline: S3 object creation → SQS → Lambda → S3 copy
- Lambda function code is in `infraestructura/lambda/lambda_function.py`; Terraform zips it automatically
- S3 bucket naming constraint: no underscores allowed (AWS restriction)
- Two required tfvars with no defaults: `storage_aws_iam_user_arn`, `storage_aws_external_id` — see `env/test.tfvars`
- Terraform native tests in `infraestructura/tests/main.tftest.hcl` use `command = plan` only
- Tests assert hardcoded bucket/function names — they document the exact intended resource names

### Snowflake Integration
- **Two runnable scripts**: `seeder.py` seeds `BOB_RAW_DATA` with 10 rows; `data_pipeline.py` exports `BOB_RAW_DATA` to the Snowflake S3 external stage in Parquet format
- `data_pipeline.py` hardcodes `BOBTEST.BOB` as database.schema — not configurable via env vars
- Credentials are in a `.env` file in `snowflake-integration/`; `get_credentials()` returns `None` silently for missing vars
- Snowflake MFA is active — must bypass before running scripts (`ALTER USER SET MINS_TO_BYPASS_MFA = 60`)
- Validates all 7 credentials before attempting connection
- Uses custom utilities in `utils/` for name/date generation (static word lists, no external libs)
- No database connection pooling — creates new connection each run
- Tests in `test/` directory; `conftest.py` patches `sys.path` so `utils/` imports resolve
- `integration.sql` is standalone DDL: table definition, Parquet file format, S3 storage integration, external stage, grants, and MFA bypass — not executed by the seeder

### Architecture Decisions
- SQS visibility timeout (180s) is 3x Lambda timeout (60s) — intentional for retry logic
- Lambda uses `copy_object()` API instead of get+put for efficiency
- Lambda event is double-nested: SQS wraps a JSON-encoded S3 event
- `prevent_destroy` lifecycle meta-argument cannot be asserted in Terraform test blocks
- SQS KMS key ARN is unknown at plan time; tests assert `kms_data_key_reuse_period_seconds` instead
