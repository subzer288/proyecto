import snowflake.connector
from snowflake.connector import DictCursor
import random


from utils.credentials import get_credentials

# Snowflake connection parameters

TABLE_NAME = "BOB_RAW_DATA"
STAGE_NAME = "SNOWFLAKE_S3_STAGE"

def main():

    credentials = get_credentials()

    # Validate credentials
    required_keys = ['user', 'password', 'account', 'warehouse', 'database', 'schema', 'role']
    for key in required_keys:
        if key not in credentials or not credentials[key]:
            raise ValueError(f"Missing required credential: {key}")

    conn = snowflake.connector.connect(**credentials)
    cursor = None

    try:
        cursor = conn.cursor()

        pipeline = f"""
          COPY INTO @{STAGE_NAME} FROM (SELECT * FROM {TABLE_NAME} ORDER BY TRANSACTION_DATE ASC )
          OVERWRITE = TRUE 
          SINGLE = FALSE 
          FILE_FORMAT = ( FORMAT_NAME = SNOWFLAKE_S3_FILE_FORMAT_PARQUET)
        """

        cursor.execute(pipeline)


    finally:
        if cursor:
            cursor.close()
        conn.close()

if __name__ == "__main__":
    main()