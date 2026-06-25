----
name: push-changes
description: Use this skill to Run terraform test and pytest, stage all changes, create a detailed commit message, commit changes and push to github
----

## GITHUB

This skill is used when the user request to push changes to github:

### Workflow

1. Move to folder infraestructura
2. Run the following script if at least one .tf file had changed:

\```bash
terraform test
\```

3. If all test passed or the terraform test was not executed, move to folder snowflake-integration
4. Run the following script if at least one .py file had changes:

\```bash
pytest --cov=. --cov-report=html
\```

5. If no errors or the pytest was not executed, stage all changes.
6. Create a detailed commit message and wait for user to approve it.
7. Commit the changes.
8. Run the following script to get the origin branch

\```bash
git status
\```

9. If branch name is no master or main, push the changes