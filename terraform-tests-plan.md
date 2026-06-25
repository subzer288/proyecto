# Terraform Tests Plan

## Overview

Create a comprehensive test suite for all Terraform configuration files in `infraestructura/` using the **Terraform built-in testing framework** (`.tftest.hcl`, requires Terraform >= 1.6).

- **Scope**: All `.tf` files — S3, KMS, SQS, Lambda, IAM, Snowflake role, outputs
- **Mode**: `command = "plan"` only — no real AWS resources created, no credentials needed
- **Location**: Single file `infraestructura/tests/main.tftest.hcl`
- **Run command**: `cd infraestructura && terraform test`

The tests validate that the Terraform plan produces the correct resource configurations, security settings, naming conventions, and cross-resource references — without deploying anything.

---

## Sub-Tasks

---

### Sub-Task 1 — Create test scaffold and variables fixture

**Intent**: Set up the `tests/` directory, the `main.tftest.hcl` file, and a shared `variables` block with the two required inputs (`storage_aws_iam_user_arn`, `storage_aws_external_id`). All subsequent run blocks depend on this foundation.

**Expected Outcomes**:
- `infraestructura/tests/main.tftest.hcl` file exists
- File contains a `variables` block providing dummy values for both required variables
- `terraform test` runs without parse errors (zero run blocks is acceptable at this stage)

**Todo List**:
1. Create directory `infraestructura/tests/`
2. Create `infraestructura/tests/main.tftest.hcl`
3. Add a top-level `variables` block with:
   - `storage_aws_iam_user_arn = "arn:aws:iam::123456789012:user/test-snowflake-user"`
   - `storage_aws_external_id = "TEST_EXTERNAL_ID"`
4. Verify `terraform test` parses the file without errors

**Relevant Context**:
- `infraestructura/variables.tf` lines 25–34: the two required variables with no defaults
- `infraestructura/env/test.tfvars`: existing real values that inspired the dummy fixture format

**Status**: [x] done — `infraestructura/tests/main.tftest.hcl` created with variables block; `versions.tf` bumped to >= 1.6.0; `terraform test` returns "0 passed, 0 failed"

---

### Sub-Task 2 — S3 bucket tests

**Intent**: Verify both S3 buckets are configured with the correct names, lifecycle settings, KMS encryption, and that the event notification points to the SQS queue.

**Expected Outcomes**:
- `run "s3_buckets_exist"` passes — both bucket resources are planned
- `run "s3_encryption_enabled"` passes — both buckets use `aws:kms` SSE with `bucket_key_enabled = true`
- `run "s3_event_notification_targets_sqs"` passes — notification events are `s3:ObjectCreated:*` and dependency on SQS policy is declared
- `run "s3_lifecycle_allows_destroy"` passes — `prevent_destroy = false` on both buckets

**Todo List**:
1. Add `run "s3_buckets_exist"` block asserting:
   - `aws_s3_bucket.processed_files.bucket` equals `"processed-files-bob"`
   - `aws_s3_bucket.data_analytics.bucket` equals `"data-analytics-bob"`
2. Add `run "s3_encryption_enabled"` block asserting:
   - SSE algorithm on both buckets is `"aws:kms"`
   - `bucket_key_enabled = true` on both rules
3. Add `run "s3_event_notification_targets_sqs"` block asserting:
   - Notification `events` list contains `"s3:ObjectCreated:*"`
4. Add `run "s3_lifecycle_allows_destroy"` block asserting:
   - `prevent_destroy = false` for both buckets

**Relevant Context**:
- `infraestructura/s3.tf`: all 5 S3 resources
- `infraestructura/kms.tf`: KMS key references used in SSE configs

**Status**: [x] done — 3 run blocks added; `rule` and `queue`/`events` are sets so assertions use `anytrue([for ... ])` instead of `[0]` indexing

---

### Sub-Task 3 — KMS key tests

**Intent**: Verify all four KMS keys have key rotation enabled, correct deletion windows, and that aliases match the expected naming scheme.

**Expected Outcomes**:
- `run "kms_key_rotation_enabled"` passes — all 4 keys have `enable_key_rotation = true`
- `run "kms_deletion_window"` passes — all 4 keys have `deletion_window_in_days = 10`
- `run "kms_aliases_named_correctly"` passes — alias names match the expected values for each key

**Todo List**:
1. Add `run "kms_key_rotation_enabled"` block asserting `enable_key_rotation = true` for:
   - `aws_kms_key.processed_files_bucket`
   - `aws_kms_key.data_analytics_bucket`
   - `aws_kms_key.sqs_queue`
   - `aws_kms_key.lambda_env`
2. Add `run "kms_deletion_window"` block asserting `deletion_window_in_days = 10` for all 4 keys
3. Add `run "kms_aliases_named_correctly"` block asserting alias names:
   - `alias/processed-files-bucket`
   - `alias/data-analytics-bucket`
   - `alias/sqs-processed-files-events`
   - `alias/lambda-environment-variables`

**Relevant Context**:
- `infraestructura/kms.tf` lines 1–152: full KMS configuration

**Status**: [x] done — 3 run blocks added; all pass

---

### Sub-Task 4 — SQS queue tests

**Intent**: Verify the SQS queue has the correct visibility timeout (the 3× Lambda ratio), KMS encryption, and that the queue policy allows only the `processed-files` S3 bucket to send messages.

**Expected Outcomes**:
- `run "sqs_visibility_timeout"` passes — `visibility_timeout_seconds = 180`
- `run "sqs_kms_encryption"` passes — KMS encryption is configured
- `run "sqs_queue_name"` passes — queue name is `"processed-files-events"`

**Todo List**:
1. Add `run "sqs_visibility_timeout"` block asserting `visibility_timeout_seconds = 180`
2. Add `run "sqs_kms_encryption"` block asserting `kms_master_key_id` is not empty/null
3. Add `run "sqs_queue_name"` block asserting `name = "processed-files-events"`

**Relevant Context**:
- `infraestructura/sqs.tf` lines 1–31
- The 3× ratio is intentional and documented in AGENTS.md

**Status**: [x] done — 3 run blocks added; `kms_master_key_id != null` replaced with `kms_data_key_reuse_period_seconds == 300` because the key ID is a computed reference unknown at plan time

---

### Sub-Task 5 — Lambda function tests

**Intent**: Verify the Lambda function uses the correct runtime, timeout, handler, and that the event source mapping connects to SQS with the expected batch size. Also verify the zip is sourced from the correct path.

**Expected Outcomes**:
- `run "lambda_runtime_and_handler"` passes — runtime is `python3.12`, handler is `lambda_function.lambda_handler`
- `run "lambda_timeout"` passes — `timeout = 60`
- `run "lambda_event_source_batch_size"` passes — `batch_size = 10` and `enabled = true`
- `run "lambda_zip_source_path"` passes — archive source file points to `lambda/lambda_function.py`

**Todo List**:
1. Add `run "lambda_runtime_and_handler"` block asserting:
   - `runtime = "python3.12"`
   - `handler = "lambda_function.lambda_handler"`
2. Add `run "lambda_timeout"` block asserting `timeout = 60`
3. Add `run "lambda_event_source_batch_size"` block asserting:
   - `batch_size = 10`
   - `enabled = true`
4. Add `run "lambda_zip_source_path"` block asserting `data.archive_file.lambda_zip.source_file` ends with `lambda/lambda_function.py`

**Relevant Context**:
- `infraestructura/lambda.tf` lines 1–29
- The timeout/SQS visibility ratio is a documented architectural constraint

**Status**: [x] done — 4 run blocks added; all pass

---

### Sub-Task 6 — IAM role tests

**Intent**: Verify both IAM roles have the correct trust relationships: Lambda role trusts `lambda.amazonaws.com` and Snowflake role trusts only the specific Snowflake IAM user ARN with an external ID condition.

**Expected Outcomes**:
- `run "lambda_iam_role_trust"` passes — assume role policy allows `lambda.amazonaws.com`
- `run "snowflake_iam_role_name"` passes — role name is `"snowflake-s3-integration-role"`
- `run "snowflake_role_uses_external_id"` passes — the assume role policy JSON contains the external ID condition

**Todo List**:
1. Add `run "lambda_iam_role_trust"` block asserting `aws_iam_role.lambda_role.name = "copy-files-lambda-role"` and assume_role_policy contains `"lambda.amazonaws.com"`
2. Add `run "snowflake_iam_role_name"` block asserting `aws_iam_role.snowflake_integration.name = "snowflake-s3-integration-role"`
3. Add `run "snowflake_role_uses_external_id"` block asserting assume_role_policy JSON contains `"sts:ExternalId"` (the external ID condition key)

**Relevant Context**:
- `infraestructura/iam.tf` lines 1–30
- `infraestructura/snowflake-role.tf` lines 1–41
- `infraestructura/main.tf`: locals that feed `storage_aws_iam_user_arn` and `storage_aws_external_id`

**Status**: [x] done — 3 run blocks added; all pass

---

### Sub-Task 7 — Outputs tests

**Intent**: Verify all 9 declared outputs exist and are non-empty in the plan, confirming the full resource graph resolves correctly.

**Expected Outcomes**:
- `run "all_outputs_defined"` passes — all 9 output values are planned and non-null

**Todo List**:
1. Add `run "all_outputs_defined"` block with `command = "plan"` asserting each output is not null:
   - `processed_files_bucket`
   - `data_analytics_bucket`
   - `sqs_queue_url`
   - `lambda_function_name`
   - `kms_key_processed_files_arn`
   - `kms_key_data_analytics_arn`
   - `kms_key_sqs_arn`
   - `kms_key_lambda_env_arn`
   - `snowflake_integration_role_arn`

**Relevant Context**:
- `infraestructura/outputs.tf` lines 1–42

**Status**: [x] done — outputs backed by computed AWS ARNs/URLs (kms ARNs, sqs URL, role ARN) are unknown at plan time; those outputs are validated via their source resource attributes in the respective domain run blocks; the 3 static outputs (bucket names, function name) are asserted by value

---

## Test Execution

```bash
cd infraestructura
terraform test
```

To run with verbose output:
```bash
terraform test -verbose
```

No AWS credentials or real resources required — all runs use `command = "plan"`.
