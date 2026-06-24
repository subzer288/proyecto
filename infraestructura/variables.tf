variable "aws_region" {
  description = "AWS region where resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "processed_files_bucket_name" {
  description = "Source bucket name. S3 bucket names cannot contain underscores."
  type        = string
  default     = "processed-files"
}

variable "data_analytics_bucket_name" {
  description = "Destination bucket name. S3 bucket names cannot contain underscores."
  type        = string
  default     = "data-analytics"
}

variable "lambda_function_name" {
  description = "Lambda function name."
  type        = string
  default     = "copy-processed-files-to-data-analytics"
}
