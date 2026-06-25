# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Structure

Three independent components:
- `infraestructura/` - Terraform AWS infrastructure (S3→SQS→Lambda pipeline)
- `snowflake-integration/` - Python scripts + Snowflake DDL for seeding and pipeline
- `snowflake-integration/integration.sql` - Manual Snowflake DDL: table, file format, storage integration, stage, grants, and MFA bypass

## Critical Non-Obvious Issues

### Terraform Deployment
- **MUST run from `infraestructura/` directory**, not project root
- Commands: `cd infraestructura && terraform init/plan/apply`
- S3 bucket names cannot contain underscores (enforced by AWS, noted in `variables.tf`)
- Two variables have no defaults and **must** be provided: `storage_aws_iam_user_arn` and `storage_aws_external_id` — use `env/test.tfvars` as a template
- Terraform auto-zips `lambda/lambda_function.py` at plan/apply time via `archive_file` data source — do not manually manage the zip
- Terraform tests assert hardcoded names (`processed-files-bob`, `data-analytics-bob`, `copy-processed-files-to-data-analytics`) — renaming any of these will break tests

### Architecture Decisions
- SQS visibility timeout (180s) is intentionally 3x Lambda timeout (60s) for retry handling
- Lambda uses `s3.copy_object()` not `s3.get_object()` + `s3.put_object()` for efficiency
- Lambda receives **nested** event structure: SQS record body contains JSON-encoded S3 event (double-parse required)
- Lambda gets `DESTINATION_BUCKET` from environment variable injected by Terraform (not hardcoded)
- Both S3 buckets use KMS encryption with separate keys defined in `kms.tf`

### Snowflake Integration
- Two runnable scripts: `seeder.py` (inserts 10 rows into `BOB_RAW_DATA`) and `data_pipeline.py` (runs `COPY INTO` from `BOB_RAW_DATA` to the Snowflake S3 stage in Parquet format)
- `data_pipeline.py` hardcodes `BOBTEST.BOB.SNOWFLAKE_S3_STAGE` and `BOBTEST.BOB.BOB_RAW_DATA` — no env var abstraction for database/schema names
- Snowflake MFA is enabled; bypass with `ALTER USER {USER} SET MINS_TO_BYPASS_MFA = 60;` before running scripts, or provide a 6-digit TOTP token
- Credentials are stored in a `.env` file in `snowflake-integration/` — load them before running scripts
- `utils/credentials.py` returns `None` values silently if env vars missing; `seeder.py` and `data_pipeline.py` validate them before connecting
- Custom name/date generators in `utils/` — do not replace with Faker or similar
- Inserts one row at a time (no batching); 10 rows per run hardcoded in `range(10)`
- SQL uses f-string interpolation (not parameterized queries) — values must be quoted in the string
- Has a local `.venv` in `snowflake-integration/` — activate it or use pip install directly

## Commands

### Terraform (from `infraestructura/` directory)
```bash
cd infraestructura
terraform init
terraform plan -var-file=env/test.tfvars
terraform apply -var-file=env/test.tfvars
terraform destroy -var-file=env/test.tfvars
terraform test                               # run HCL tests in tests/main.tftest.hcl
```

### Snowflake Integration
```bash
cd snowflake-integration
pip install -r requirements.txt
# Set env vars from .env: SNOWFLAKE_USER, SNOWFLAKE_PASSWORD, SNOWFLAKE_ACCOUNT,
# SNOWFLAKE_WAREHOUSE, SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA, SNOWFLAKE_ROLE
python seeder.py         # insert 10 rows into BOB_RAW_DATA
python data_pipeline.py  # COPY BOB_RAW_DATA rows into S3 stage as Parquet
```

### Tests (from `snowflake-integration/` directory)
```bash
cd snowflake-integration
pytest                        # run all tests
pytest test/test_seeder.py    # run single file
pytest test/test_seeder.py::TestSeeder::test_main_creates_table_and_inserts_records  # single test
```

## Code Patterns

- Terraform: AWS provider ~> 5.0, Terraform >= 1.5.0; Terraform native tests in `infraestructura/tests/main.tftest.hcl`
- Terraform tests use `command = plan` (not `apply`) — safe to run without AWS credentials configured
- Python: Uses boto3 for AWS, snowflake-connector-python for Snowflake
- Lambda: Python 3.12 runtime, processes SQS batches of S3 events
- Tests: pytest with `unittest.mock`; `conftest.py` adds parent dir to `sys.path` so `utils/` imports work from `test/`
- `prevent_destroy` lifecycle meta-argument cannot be tested via Terraform `assert` blocks (not a plan-time attribute)
- SQS `kms_master_key_id` is unknown at plan time — tests assert `kms_data_key_reuse_period_seconds` instead to verify KMS is configured
