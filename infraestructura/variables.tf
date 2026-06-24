variable "aws_region" {
  description = "AWS region where resources will be deployed."
  type        = string
  default     = "us-east-2"
}

variable "processed_files_bucket_name" {
  description = "Source bucket name. S3 bucket names cannot contain underscores."
  type        = string
  default     = "processed-files-bob"
}

variable "data_analytics_bucket_name" {
  description = "Destination bucket name. S3 bucket names cannot contain underscores."
  type        = string
  default     = "data-analytics-bob"
}

variable "lambda_function_name" {
  description = "Lambda function name."
  type        = string
  default     = "copy-processed-files-to-data-analytics"
}

variable "storage_aws_iam_user_arn" {
  description = "The AWS IAM user created for your Snowflake account; for example, arn:aws:iam::123456789001:user/abc1-b-self1234. Snowflake provisions a single IAM user for your entire Snowflake account. All S3 storage integrations in your account use that IAM user."
  type        = string
}

variable "storage_aws_external_id" {
  description = "The external ID that Snowflake uses to establish a trust relationship with AWS. If you didn’t specify an external ID (STORAGE_AWS_EXTERNAL_ID) when you created the storage integration, Snowflake generates an ID for you to use."
  type        = string
}

