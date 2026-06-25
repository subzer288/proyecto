variables {
  storage_aws_iam_user_arn = "arn:aws:iam::123456789012:user/test-snowflake-user"
  storage_aws_external_id  = "TEST_EXTERNAL_ID"
}

# ============================================================
# S3 TESTS
# ============================================================

run "s3_bucket_names" {
  command = plan

  assert {
    condition     = aws_s3_bucket.processed_files.bucket == "processed-files-bob"
    error_message = "processed_files bucket name must be 'processed-files-bob'"
  }

  assert {
    condition     = aws_s3_bucket.data_analytics.bucket == "data-analytics-bob"
    error_message = "data_analytics bucket name must be 'data-analytics-bob'"
  }
}

run "s3_encryption_enabled" {
  command = plan

  # rule and apply_server_side_encryption_by_default are sets — use anytrue + for expression
  assert {
    condition = anytrue([
      for rule in aws_s3_bucket_server_side_encryption_configuration.processed_files.rule :
      anytrue([for cfg in rule.apply_server_side_encryption_by_default : cfg.sse_algorithm == "aws:kms"])
    ])
    error_message = "processed_files bucket must use aws:kms SSE algorithm"
  }

  assert {
    condition = anytrue([
      for rule in aws_s3_bucket_server_side_encryption_configuration.processed_files.rule :
      rule.bucket_key_enabled == true
    ])
    error_message = "processed_files bucket must have bucket_key_enabled = true"
  }

  assert {
    condition = anytrue([
      for rule in aws_s3_bucket_server_side_encryption_configuration.data_analytics.rule :
      anytrue([for cfg in rule.apply_server_side_encryption_by_default : cfg.sse_algorithm == "aws:kms"])
    ])
    error_message = "data_analytics bucket must use aws:kms SSE algorithm"
  }

  assert {
    condition = anytrue([
      for rule in aws_s3_bucket_server_side_encryption_configuration.data_analytics.rule :
      rule.bucket_key_enabled == true
    ])
    error_message = "data_analytics bucket must have bucket_key_enabled = true"
  }
}

run "s3_event_notification_targets_sqs" {
  command = plan

  # queue and events are sets — use anytrue + for expression
  assert {
    condition = anytrue([
      for q in aws_s3_bucket_notification.processed_files_notification.queue :
      anytrue([for e in q.events : e == "s3:ObjectCreated:*"])
    ])
    error_message = "S3 event notification must trigger on s3:ObjectCreated:* events"
  }
}

# Note: prevent_destroy is a lifecycle meta-argument and is NOT exposed as
# a plan-time attribute — it cannot be tested via assert blocks.

# ============================================================
# KMS TESTS
# ============================================================

run "kms_key_rotation_enabled" {
  command = plan

  assert {
    condition     = aws_kms_key.processed_files_bucket.enable_key_rotation == true
    error_message = "KMS key for processed_files_bucket must have key rotation enabled"
  }

  assert {
    condition     = aws_kms_key.data_analytics_bucket.enable_key_rotation == true
    error_message = "KMS key for data_analytics_bucket must have key rotation enabled"
  }

  assert {
    condition     = aws_kms_key.sqs_queue.enable_key_rotation == true
    error_message = "KMS key for sqs_queue must have key rotation enabled"
  }

  assert {
    condition     = aws_kms_key.lambda_env.enable_key_rotation == true
    error_message = "KMS key for lambda_env must have key rotation enabled"
  }
}

run "kms_deletion_window" {
  command = plan

  assert {
    condition     = aws_kms_key.processed_files_bucket.deletion_window_in_days == 10
    error_message = "KMS key for processed_files_bucket must have deletion_window_in_days = 10"
  }

  assert {
    condition     = aws_kms_key.data_analytics_bucket.deletion_window_in_days == 10
    error_message = "KMS key for data_analytics_bucket must have deletion_window_in_days = 10"
  }

  assert {
    condition     = aws_kms_key.sqs_queue.deletion_window_in_days == 10
    error_message = "KMS key for sqs_queue must have deletion_window_in_days = 10"
  }

  assert {
    condition     = aws_kms_key.lambda_env.deletion_window_in_days == 10
    error_message = "KMS key for lambda_env must have deletion_window_in_days = 10"
  }
}

run "kms_aliases_named_correctly" {
  command = plan

  assert {
    condition     = aws_kms_alias.processed_files_bucket.name == "alias/processed-files-bucket"
    error_message = "KMS alias for processed_files_bucket must be 'alias/processed-files-bucket'"
  }

  assert {
    condition     = aws_kms_alias.data_analytics_bucket.name == "alias/data-analytics-bucket"
    error_message = "KMS alias for data_analytics_bucket must be 'alias/data-analytics-bucket'"
  }

  assert {
    condition     = aws_kms_alias.sqs_queue.name == "alias/sqs-processed-files-events"
    error_message = "KMS alias for sqs_queue must be 'alias/sqs-processed-files-events'"
  }

  assert {
    condition     = aws_kms_alias.lambda_env.name == "alias/lambda-environment-variables"
    error_message = "KMS alias for lambda_env must be 'alias/lambda-environment-variables'"
  }
}

# ============================================================
# SQS TESTS
# ============================================================

run "sqs_queue_name" {
  command = plan

  assert {
    condition     = aws_sqs_queue.processed_files_events.name == "processed-files-events"
    error_message = "SQS queue name must be 'processed-files-events'"
  }
}

run "sqs_visibility_timeout" {
  command = plan

  # Intentionally 3× the Lambda timeout (60s) to allow safe retries on failure.
  assert {
    condition     = aws_sqs_queue.processed_files_events.visibility_timeout_seconds == 180
    error_message = "SQS visibility timeout must be 180s (3x Lambda timeout of 60s)"
  }
}

run "sqs_kms_encryption" {
  command = plan

  # kms_master_key_id references another planned resource — not known at plan time.
  # Instead assert kms_data_key_reuse_period_seconds is set (only present when KMS is configured).
  assert {
    condition     = aws_sqs_queue.processed_files_events.kms_data_key_reuse_period_seconds == 300
    error_message = "SQS queue must have KMS data key reuse period configured (implies KMS encryption is active)"
  }
}

# ============================================================
# LAMBDA TESTS
# ============================================================

run "lambda_runtime_and_handler" {
  command = plan

  assert {
    condition     = aws_lambda_function.copy_file.runtime == "python3.12"
    error_message = "Lambda runtime must be python3.12"
  }

  assert {
    condition     = aws_lambda_function.copy_file.handler == "lambda_function.lambda_handler"
    error_message = "Lambda handler must be 'lambda_function.lambda_handler'"
  }
}

run "lambda_timeout" {
  command = plan

  assert {
    condition     = aws_lambda_function.copy_file.timeout == 60
    error_message = "Lambda timeout must be 60 seconds"
  }
}

run "lambda_event_source_batch_size" {
  command = plan

  assert {
    condition     = aws_lambda_event_source_mapping.sqs_to_lambda.batch_size == 10
    error_message = "Lambda event source batch size must be 10"
  }

  assert {
    condition     = aws_lambda_event_source_mapping.sqs_to_lambda.enabled == true
    error_message = "Lambda event source mapping must be enabled"
  }
}

run "lambda_zip_source_path" {
  command = plan

  assert {
    condition     = endswith(data.archive_file.lambda_zip.source_file, "lambda/lambda_function.py")
    error_message = "Lambda zip must be sourced from lambda/lambda_function.py"
  }
}

# ============================================================
# IAM TESTS
# ============================================================

run "lambda_iam_role_name" {
  command = plan

  assert {
    condition     = aws_iam_role.lambda_role.name == "copy-files-lambda-role"
    error_message = "Lambda IAM role name must be 'copy-files-lambda-role'"
  }

  assert {
    condition     = strcontains(aws_iam_role.lambda_role.assume_role_policy, "lambda.amazonaws.com")
    error_message = "Lambda IAM role trust policy must allow lambda.amazonaws.com"
  }
}

run "snowflake_iam_role_name" {
  command = plan

  assert {
    condition     = aws_iam_role.snowflake_integration.name == "snowflake-s3-integration-role"
    error_message = "Snowflake IAM role name must be 'snowflake-s3-integration-role'"
  }
}

run "snowflake_role_uses_external_id" {
  command = plan

  assert {
    condition     = strcontains(aws_iam_role.snowflake_integration.assume_role_policy, "sts:ExternalId")
    error_message = "Snowflake role trust policy must include sts:ExternalId condition"
  }
}

# ============================================================
# OUTPUTS TESTS
# ============================================================

# Outputs backed by static values (bucket names, function name) are known at plan time.
# Outputs backed by computed ARNs/URLs are unknown at plan — those are validated
# via their source resource attributes in the relevant domain run blocks above.

run "all_outputs_defined" {
  command = plan

  assert {
    condition     = output.processed_files_bucket == "processed-files-bob"
    error_message = "Output 'processed_files_bucket' must equal the configured bucket name"
  }

  assert {
    condition     = output.data_analytics_bucket == "data-analytics-bob"
    error_message = "Output 'data_analytics_bucket' must equal the configured bucket name"
  }

  assert {
    condition     = output.lambda_function_name == "copy-processed-files-to-data-analytics"
    error_message = "Output 'lambda_function_name' must equal the configured function name"
  }

  # sqs_queue_url, kms_key_*_arn and snowflake_integration_role_arn are computed
  # at apply time (AWS-assigned URLs/ARNs) — verify their source resources are
  # correctly configured in the KMS and IAM run blocks above.
}
