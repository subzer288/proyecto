# AWS Event-Driven File Processing Pipeline

This Terraform project deploys a secure, event-driven file processing pipeline on AWS that automatically copies files from a source S3 bucket to a destination bucket using Lambda functions triggered by SQS messages.

## Architecture Overview

```
S3 (processed-files) → S3 Event → SQS Queue → Lambda Function → S3 (data-analytics)
         ↓                           ↓              ↓                    ↓
    KMS Encrypted              KMS Encrypted   KMS Encrypted       KMS Encrypted
```

## Components

### Storage
- **Source S3 Bucket** (`processed-files`): Receives incoming files
- **Destination S3 Bucket** (`data-analytics`): Stores processed/copied files
- Both buckets have:
  - Server-side encryption with KMS
  - Public access blocked
  - Bucket key enabled for cost optimization

### Messaging
- **SQS Queue** (`processed-files-events`): Buffers S3 events
  - Visibility timeout: 180 seconds (3x Lambda timeout for retry handling)
  - KMS encryption enabled
  - Data key reuse period: 300 seconds

### Compute
- **Lambda Function** (`copy-processed-files-to-data-analytics`):
  - Runtime: Python 3.12
  - Timeout: 60 seconds
  - Batch size: 10 SQS messages
  - Uses `s3.copy_object()` for efficient server-side copying
  - Environment variables encrypted with KMS

### Security
- **4 KMS Keys** with automatic rotation:
  1. `processed-files-bucket-key`: Encrypts source S3 bucket
  2. `data-analytics-bucket-key`: Encrypts destination S3 bucket
  3. `sqs-queue-key`: Encrypts SQS messages
  4. `lambda-env-key`: Encrypts Lambda environment variables

- **IAM Role** with least-privilege permissions:
  - Read from source bucket
  - Write to destination bucket
  - Poll and delete SQS messages
  - Decrypt with all KMS keys
  - Write CloudWatch logs

## File Structure

```
infraestructura/
├── provider.tf              # AWS provider configuration
├── versions.tf              # Terraform and provider version constraints
├── variables.tf             # Input variables (region, bucket names, etc.)
├── s3.tf                    # S3 buckets with encryption
├── sqs.tf                   # SQS queue with KMS encryption
├── s3_notifications.tf      # S3 event notifications to SQS
├── kms.tf                   # KMS keys for encryption
├── iam.tf                   # IAM roles and policies for Lambda
├── lambda.tf                # Lambda function and event source mapping
├── outputs.tf               # Output values (bucket names, ARNs, etc.)
└── lambda/
    └── lambda_function.py   # Lambda handler code
```

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create:
  - S3 buckets
  - SQS queues
  - Lambda functions
  - IAM roles and policies
  - KMS keys

## Deployment

**Important**: All Terraform commands must be run from the `infraestructura/` directory.

```bash
# Navigate to infrastructure directory
cd infraestructura

# Initialize Terraform
terraform init

# Review planned changes
terraform plan -var-file="env/test.tfvars" -out="shared/tfplan"

# Deploy infrastructure
terraform apply "shared/tfplan"

# Destroy infrastructure (when needed)
terraform destroy
```

## Configuration

### Variables

You can customize the deployment by modifying `variables.tf` or using a `terraform.tfvars` file:

```hcl
aws_region                   = "us-east-1"
processed_files_bucket_name  = "processed-files"
data_analytics_bucket_name   = "data-analytics"
lambda_function_name         = "copy-processed-files-to-data-analytics"
```

**Note**: S3 bucket names cannot contain underscores (AWS restriction).

## How It Works

1. **File Upload**: A file is uploaded to the `processed-files` S3 bucket
2. **Event Notification**: S3 sends an event notification to the SQS queue
3. **Message Buffering**: SQS stores the event message with 180s visibility timeout
4. **Lambda Trigger**: Lambda polls SQS and processes up to 10 messages per batch
5. **File Copy**: Lambda uses `s3.copy_object()` to copy files to `data-analytics` bucket
6. **Message Deletion**: Lambda deletes processed messages from SQS
7. **Encryption**: All data at rest and in transit is encrypted with KMS

## Outputs

After deployment, Terraform outputs:

- `processed_files_bucket`: Source bucket name
- `data_analytics_bucket`: Destination bucket name
- `sqs_queue_url`: SQS queue URL
- `lambda_function_name`: Lambda function name
- `kms_key_*_arn`: ARNs of all KMS keys

## Security Features

- **Encryption at Rest**: All S3 buckets, SQS messages, and Lambda environment variables encrypted with KMS
- **Encryption in Transit**: All AWS service communications use TLS
- **Key Rotation**: KMS keys automatically rotate annually
- **Least Privilege**: IAM policies grant only necessary permissions
- **Public Access Blocked**: S3 buckets block all public access
- **Audit Trail**: CloudWatch Logs capture all Lambda executions

## Cost Optimization

- **S3 Bucket Keys**: Reduces KMS API calls by up to 99%
- **SQS Data Key Reuse**: Reuses data keys for 5 minutes
- **Server-Side Copy**: Lambda uses `copy_object()` instead of download+upload
- **Batch Processing**: Lambda processes up to 10 messages per invocation

## Monitoring

Lambda execution logs are available in CloudWatch Logs:
- Log group: `/aws/lambda/copy-processed-files-to-data-analytics`
- Includes copy operations and any errors

## Troubleshooting

### Lambda Timeout
- Current timeout: 60 seconds
- SQS visibility timeout: 180 seconds (3x for retry handling)
- If files are large, consider increasing Lambda timeout

### Permission Errors
- Verify IAM role has KMS decrypt permissions
- Check KMS key policies allow Lambda role access

### Files Not Copying
- Check CloudWatch Logs for errors
- Verify S3 event notifications are configured
- Ensure SQS queue is receiving messages

## Architecture Decisions

- **SQS as Buffer**: Decouples S3 from Lambda, provides retry mechanism
- **3x Timeout Ratio**: SQS visibility (180s) is 3x Lambda timeout (60s) for proper retry handling
- **Server-Side Copy**: Uses `copy_object()` for efficiency (no data transfer through Lambda)
- **Separate KMS Keys**: Isolates encryption domains for better security
- **Batch Processing**: Processes 10 messages per invocation for efficiency
