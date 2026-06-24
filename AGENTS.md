# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Structure

Two independent components:
- `infraestructura/` - Terraform AWS infrastructure (S3→SQS→Lambda pipeline)
- `snowflake-seeder/` - Python script to seed Snowflake database

## Critical Non-Obvious Issues

### Terraform Deployment
- **MUST run from `infraestructura/` directory**, not project root
- Commands: `cd infraestructura && terraform init/plan/apply`
- S3 bucket names cannot contain underscores (enforced by AWS, noted in `variables.tf`)
- Two variables have no defaults and **must** be provided: `storage_aws_iam_user_arn` and `storage_aws_external_id` — use `env/test.tfvars` as a template
- Terraform auto-zips `lambda/lambda_function.py` at plan/apply time via `archive_file` data source — do not manually manage the zip

### Architecture Decisions
- SQS visibility timeout (180s) is intentionally 3x Lambda timeout (60s) for retry handling
- Lambda uses `s3.copy_object()` not `s3.get_object()` + `s3.put_object()` for efficiency
- Lambda receives **nested** event structure: SQS record body contains JSON-encoded S3 event (double-parse required)
- Lambda gets `DESTINATION_BUCKET` from environment variable injected by Terraform (not hardcoded)
- Both S3 buckets use KMS encryption with separate keys defined in `kms.tf`

### Snowflake Seeder
- Credentials loaded from environment variables via `utils/credentials.py` — returns `None` values silently if env vars missing; `seeder.py` validates them before connecting
- Custom name/date generators in `utils/` — do not replace with Faker or similar
- Inserts one row at a time (no batching); 10 rows per run hardcoded in `range(10)`
- SQL uses f-string interpolation (not parameterized queries) — values must be quoted in the string

## Commands

### Terraform (from `infraestructura/` directory)
```bash
cd infraestructura
terraform init
terraform plan -var-file=env/test.tfvars
terraform apply -var-file=env/test.tfvars
terraform destroy -var-file=env/test.tfvars
```

### Snowflake Seeder
```bash
cd snowflake-seeder
pip install -r requirements.txt
# Set env vars: SNOWFLAKE_USER, SNOWFLAKE_PASSWORD, SNOWFLAKE_ACCOUNT,
# SNOWFLAKE_WAREHOUSE, SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA, SNOWFLAKE_ROLE
python seeder.py
```

### Tests (from `snowflake-seeder/` directory)
```bash
cd snowflake-seeder
pytest                        # run all tests
pytest test/test_seeder.py    # run single file
pytest test/test_seeder.py::TestSeeder::test_main_creates_table_and_inserts_records  # single test
```

## Code Patterns

- Terraform: AWS provider ~> 5.0, Terraform >= 1.5.0
- Python: Uses boto3 for AWS, snowflake-connector-python for Snowflake
- Lambda: Python 3.12 runtime, processes SQS batches of S3 events
- Tests: pytest with `unittest.mock`; `conftest.py` adds parent dir to `sys.path` so `utils/` imports work from `test/`
