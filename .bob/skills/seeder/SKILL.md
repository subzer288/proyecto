----
name: seeder
description: Use this skill to insert randomized data in snowflake.
----

## SNOWFLAKE

This skill is used when the user :

### Workflow

1. Move to folder snowflake-integration.
2. set the credentias stored in the .env file and run the seeder script.
3. Ask the user to Bypass MFA running next query in Snowflake "ALTER USER {USER} SET MINS_TO_BYPASS_MFA = 60;" 
4. If user rejects the proprosal ask to provide the 6 digit TOTP token from his authenticator app.
5. If non of these options were approved, finish the skill execution.

6. Run seeder.py
