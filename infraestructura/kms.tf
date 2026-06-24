# KMS Key for S3 Bucket: processed-files
resource "aws_kms_key" "processed_files_bucket" {
  description             = "KMS key for encrypting processed-files S3 bucket"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "processed-files-bucket-key"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "processed_files_bucket" {
  name          = "alias/processed-files-bucket"
  target_key_id = aws_kms_key.processed_files_bucket.key_id
}

# KMS Key for S3 Bucket: data-analytics
resource "aws_kms_key" "data_analytics_bucket" {
  description             = "KMS key for encrypting data-analytics S3 bucket"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "data-analytics-bucket-key"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "data_analytics_bucket" {
  name          = "alias/data-analytics-bucket"
  target_key_id = aws_kms_key.data_analytics_bucket.key_id
}

# KMS Key for SQS Queue
resource "aws_kms_key" "sqs_queue" {
  description             = "KMS key for encrypting SQS queue messages"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 to use the key"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow SQS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda to use the key"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_role.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "sqs-queue-key"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "sqs_queue" {
  name          = "alias/sqs-processed-files-events"
  target_key_id = aws_kms_key.sqs_queue.key_id
}

# KMS Key for Lambda Environment Variables
resource "aws_kms_key" "lambda_env" {
  description             = "KMS key for encrypting Lambda environment variables"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda to use the key"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "lambda-env-key"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "lambda_env" {
  name          = "alias/lambda-environment-variables"
  target_key_id = aws_kms_key.lambda_env.key_id
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}