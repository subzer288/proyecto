# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Structure

Two independent components:
- `infraestructura/` - Terraform AWS infrastructure (S3→SQS→Lambda pipeline)
- `snowflake-seeder/` - Python script to seed Snowflake database

## Critical Non-Obvious Issues

### Snowflake Seeder Bugs
The `snowflake-seeder/seeder.py` file has several bugs that must be fixed:
- Line 30: Missing comma after `AMOUNT DECIMAL(6,2)`
- Line 38: Should be `range(10)` not `for i in 10:`
- Line 39: Should call function `generate_random_name()` not reference it
- Line 16: Should call `get_credentials()` not use `get_credentials` as dict
- Line 51: SQL values need proper quoting - use parameterized queries or f-string with quotes

### Terraform Deployment
- **MUST run from `infraestructura/` directory**, not project root
- Commands: `cd infraestructura && terraform init/plan/apply`
- S3 bucket names cannot contain underscores (enforced by AWS, noted in variables.tf)

### Architecture Decisions
- SQS visibility timeout (180s) is intentionally 3x Lambda timeout (60s) for retry handling
- Lambda uses `s3.copy_object()` not `s3.get_object()` + `s3.put_object()` for efficiency
- Snowflake credentials loaded from environment variables via `utils/credentials.py`

## Commands

### Terraform (from infraestructura/ directory)
```bash
cd infraestructura
terraform init
terraform plan
terraform apply
terraform destroy
```

### Snowflake Seeder
```bash
cd snowflake-seeder
pip install -r requirements.txt
# Set environment variables: SNOWFLAKE_USER, SNOWFLAKE_PASSWORD, SNOWFLAKE_ACCOUNT, 
# SNOWFLAKE_WAREHOUSE, SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA, SNOWFLAKE_ROLE
python seeder.py
```

## Code Patterns

- Terraform: AWS provider ~> 5.0, Terraform >= 1.5.0
- Python: Uses boto3 for AWS, snowflake-connector-python for Snowflake
- Lambda: Python 3.12 runtime, processes SQS batches of S3 events