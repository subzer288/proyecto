provider "aws" {
  region = var.aws_region
}

# Main Terraform Configuration
# This file serves as the entry point for the infrastructure deployment

# Local variables to load environment-specific configurations
locals {
  
  storage_aws_iam_user_arn = var.storage_aws_iam_user_arn
  storage_aws_external_id = var.storage_aws_external_id

}

# Data source to parse tfvars file (if needed for dynamic configuration)
# Note: Terraform automatically loads .tfvars files, but this provides explicit control