output "processed_files_bucket" {
  value = aws_s3_bucket.processed_files.bucket
}

output "data_analytics_bucket" {
  value = aws_s3_bucket.data_analytics.bucket
}

output "sqs_queue_url" {
  value = aws_sqs_queue.processed_files_events.url
}

output "lambda_function_name" {
  value = aws_lambda_function.copy_file.function_name
}

output "kms_key_processed_files_arn" {
  description = "ARN of KMS key for processed-files bucket"
  value       = aws_kms_key.processed_files_bucket.arn
}

output "kms_key_data_analytics_arn" {
  description = "ARN of KMS key for data-analytics bucket"
  value       = aws_kms_key.data_analytics_bucket.arn
}

output "kms_key_sqs_arn" {
  description = "ARN of KMS key for SQS queue"
  value       = aws_kms_key.sqs_queue.arn
}

output "kms_key_lambda_env_arn" {
  description = "ARN of KMS key for Lambda environment variables"
  value       = aws_kms_key.lambda_env.arn
}
