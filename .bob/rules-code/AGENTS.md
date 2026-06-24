# Code Mode Rules (Non-Obvious Only)

## Critical Bugs in Existing Code

### snowflake-seeder/seeder.py
- Line 16: `get_credentials` must be called as function: `get_credentials()`
- Line 30: Missing comma after `AMOUNT DECIMAL(6,2)` - add `,` before `CREATED_AT`
- Line 38: Wrong loop syntax - use `range(10)` not `for i in 10:`
- Line 39: Must call function - use `generate_random_name()` not `generate_random_name`
- Line 51: SQL injection risk - values need quotes. Use parameterized queries or proper f-string formatting

### snowflake-seeder/utils/date_generator.py
- Line 13: Debug print statement should be removed in production

## Terraform Constraints

- **MUST run terraform commands from `infraestructura/` directory**, not project root
- S3 bucket names cannot contain underscores (AWS restriction, enforced in variables.tf)
- Lambda timeout is 60s, SQS visibility timeout is 180s (3x) - this is intentional for retry handling

## Architecture Patterns

- Lambda uses `s3.copy_object()` for efficiency (not get + put)
- Snowflake credentials loaded via `utils/credentials.py` from environment variables
- Lambda processes SQS batches, each containing S3 event records (nested structure)