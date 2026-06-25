# Plan Mode Rules (Non-Obvious Only)

## Architectural Constraints

### Two Independent Systems
- `infraestructura/` and `snowflake-integration/` are completely separate
- No shared code, dependencies, or deployment process

### Terraform Infrastructure Architecture
- Event-driven pipeline: S3 (source) → SQS → Lambda → S3 (destination)
- Lambda triggered by SQS, not directly by S3 (decoupling pattern)
- SQS acts as buffer with 180s visibility timeout (3x Lambda's 60s timeout) — intentional for retry handling
- All four KMS keys (processed-files-bucket, data-analytics-bucket, sqs-queue, lambda-env) are separate resources in `kms.tf`
- Lambda zip is auto-generated from source at plan/apply time — never manually manage it
- Terraform native tests in `infraestructura/tests/main.tftest.hcl`; all use `command = plan` (safe, no AWS calls)

### Snowflake Integration Architecture
- Stateless script — no persistent connections or state
- Credentials from environment variables only (no config files); silent `None` on missing vars
- Custom utilities for data generation (`utils/`) — not using Faker or similar libraries
- No transaction management — each insert is auto-committed
- Tests mock all external calls; `conftest.py` patches `sys.path` for import resolution
- `integration.sql` is standalone DDL for Snowflake S3 external stage — manual execution, separate from seeder

## Hidden Coupling & Dependencies

### Terraform
- Lambda code must be in `infraestructura/lambda/` directory (path hardcoded in `lambda.tf`)
- Terraform must run from `infraestructura/` directory (not root)
- S3 bucket names have AWS constraint: no underscores allowed
- `storage_aws_iam_user_arn` and `storage_aws_external_id` have no defaults — require `-var-file=env/test.tfvars`
- `prevent_destroy` lifecycle cannot be asserted in Terraform test blocks (not a plan-time attribute)

### Snowflake Integration
- Requires exactly 7 environment variables; missing any → `ValueError` at runtime (validated in `seeder.py`)
- `test/conftest.py` must exist for test imports to work (`sys.path` manipulation)

## Performance Considerations

- Lambda uses `copy_object()` API (server-side copy) instead of download+upload
- No batching in Snowflake seeder — inserts one record at a time
- SQS batch size is 10 messages per Lambda invocation
