resource "aws_s3_bucket_notification" "processed_files_notification" {
  bucket = aws_s3_bucket.processed_files.id

  queue {
    queue_arn = aws_sqs_queue.processed_files_events.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sqs_queue_policy.allow_s3_events]
}
