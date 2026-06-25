import snowflake.connector
from snowflake.connector import DictCursor
import random


from utils.credentials import get_credentials
from utils.name_generator import generate_random_name
from utils.date_generator import random_date

# Snowflake connection parameters


TABLE_NAME = "BOB_RAW_DATA"

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

        # Create table if it doesn't exist
        create_table_sql = f"""
        CREATE TABLE IF NOT EXISTS {TABLE_NAME} (
            id UUID DEFAULT UUID_STRING() NOT NULL,
            NAME STRING,
            EMAIL STRING,
            NSS NUMBER,
            TRANSACTION_DATE DATE,
            AMOUNT DECIMAL(6,2),
            CREATED_AT TIMESTAMP_NTZ
        )
        """

        cursor.execute(create_table_sql)

        # Sample records
        
        for i in range(10):
            name = generate_random_name()
            random_row = {
                "name" : name,
                "email" : f"{name}@example.com",
                "nss": random.randint(1, 999999999),
                "trans_date" : random_date(),
                "amount" : round(random.uniform(0, 9999), 2)
            }

            insert_sql = f"""
            INSERT INTO {TABLE_NAME}
            (NAME, EMAIL, NSS, TRANSACTION_DATE, AMOUNT, CREATED_AT)
            VALUES ('{random_row['name']}', '{random_row['email']}', {random_row['nss']}, '{random_row['trans_date']}', {random_row['amount']}, CURRENT_TIMESTAMP())
            """

            cursor.execute(insert_sql)


    finally:
        if cursor:
            cursor.close()
        conn.close()

if __name__ == "__main__":
    main()