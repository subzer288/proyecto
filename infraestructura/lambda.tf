data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "copy_file" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 60
  kms_key_arn      = aws_kms_key.lambda_env.arn

  environment {
    variables = {
      DESTINATION_BUCKET = aws_s3_bucket.data_analytics.bucket
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.processed_files_events.arn
  function_name    = aws_lambda_function.copy_file.arn
  batch_size       = 10
  enabled          = true
}
