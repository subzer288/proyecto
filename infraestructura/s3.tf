resource "aws_s3_bucket" "processed_files" {
  bucket = var.processed_files_bucket_name

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [bucket]
  }
}

resource "aws_s3_bucket" "data_analytics" {
  bucket = var.data_analytics_bucket_name

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [bucket]
  }
}

resource "aws_s3_bucket_notification" "processed_files_notification" {
  bucket = aws_s3_bucket.processed_files.id

  queue {
    queue_arn = aws_sqs_queue.processed_files_events.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sqs_queue_policy.allow_s3_events]
}

# Enable server-side encryption for processed-files bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "processed_files" {
  bucket = aws_s3_bucket.processed_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.processed_files_bucket.arn
    }
    bucket_key_enabled = true
  }
}

# Enable server-side encryption for data-analytics bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "data_analytics" {
  bucket = aws_s3_bucket.data_analytics.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data_analytics_bucket.arn
    }
    bucket_key_enabled = true
  }
}
