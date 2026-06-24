# IAM Role for Snowflake Integration
# This role allows Snowflake to access the processed-files S3 bucket

resource "aws_iam_role" "snowflake_integration" {
  name = "snowflake-s3-integration-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": local.storage_aws_iam_user_arn
        }
        "Action": "sts:AssumeRole",
        "Condition": {
          "StringEquals": {
            "sts:ExternalId": local.storage_aws_external_id
          }
        }
      }
    ]
  })

  tags = {
    Name        = "snowflake-integration-role"
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "Snowflake S3 Integration"
  }
}

resource "aws_iam_role_policy" "snowflake_s3_access" {
  name = "snowflake-s3-access-policy"
  role = aws_iam_role.snowflake_integration.id

  policy = templatefile("${path.module}/policies/snowflake-role-policy.json.tfpl", {
    processed_files_bucket_arn = aws_s3_bucket.processed_files.arn
    kms_processed_files_arn    = aws_kms_key.processed_files_bucket.arn
  })
}