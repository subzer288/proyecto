resource "aws_sqs_queue" "processed_files_events" {
  name                       = "processed-files-events"
  visibility_timeout_seconds = 180
  kms_master_key_id          = aws_kms_key.sqs_queue.id
  kms_data_key_reuse_period_seconds = 300
}

resource "aws_sqs_queue_policy" "allow_s3_events" {
  queue_url = aws_sqs_queue.processed_files_events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3SendMessage"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.processed_files_events.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.processed_files.arn
          }
        }
      }
    ]
  })
}
