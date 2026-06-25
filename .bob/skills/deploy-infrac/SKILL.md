----
name: deploy-infrac
description: Use this skill to Test, Plan and Deploy Terraform Infraestructure
----

## Terraform

This skill is used when the user requests a terraform deployment.
You need to follow the next steps:

### Workflow

1. Move to folder infraestructura
2. Run the following script:

\```bash
terraform test
\```

3. If all test passed, run the following script:

\```bash
terraform plan -var-file="env/test.tfvars" -out="shared/tfplan"
\```

4. If no errors, run the following script:

\```bash
terraform apply "shared/tfplan"
\```