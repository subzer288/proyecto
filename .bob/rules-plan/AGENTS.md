# Plan Mode Rules (Non-Obvious Only)

## Architectural Constraints

### Two Independent Systems
- `infraestructura/` and `snowflake-seeder/` are completely separate
- No shared code, dependencies, or deployment process
- Each can be deployed/run independently

### Terraform Infrastructure Architecture
- Event-driven pipeline: S3 (source) → SQS → Lambda → S3 (destination)
- Lambda triggered by SQS, not directly by S3 (decoupling pattern)
- SQS acts as buffer with 180s visibility timeout (3x Lambda's 60s timeout)
- This 3x ratio is intentional for retry handling on failures

### Snowflake Seeder Architecture
- Stateless script - no persistent connections or state
- Credentials from environment variables only (no config files)
- Custom utilities for data generation (not using Faker or similar libraries)
- No transaction management - each insert is auto-committed

## Hidden Coupling & Dependencies

### Terraform
- Lambda code must be in `infraestructura/lambda/` directory
- Terraform must run from `infraestructura/` directory (not root)
- S3 bucket names have AWS constraint: no underscores allowed

### Snowflake Seeder
- Requires 7 environment variables to be set before running
- No validation of credentials before attempting connection
- Will fail silently if environment variables are missing

## Performance Considerations

- Lambda uses `copy_object()` API (server-side copy) instead of download+upload
- No batching in Snowflake seeder - inserts one record at a time
- SQS batch size is 10 messages per Lambda invocation