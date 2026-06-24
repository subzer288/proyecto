resource "aws_iam_role" "lambda_role" {
  name = "copy-files-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "copy-files-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = templatefile("${path.module}/policies/lambda-role-policy.json.tfpl", {
    processed_files_bucket_arn = aws_s3_bucket.processed_files.arn
    data_analytics_bucket_arn  = aws_s3_bucket.data_analytics.arn
    sqs_queue_arn              = aws_sqs_queue.processed_files_events.arn
    kms_processed_files_arn    = aws_kms_key.processed_files_bucket.arn
    kms_data_analytics_arn     = aws_kms_key.data_analytics_bucket.arn
    kms_sqs_arn                = aws_kms_key.sqs_queue.arn
  })
}
