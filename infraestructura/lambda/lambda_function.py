import json
import os
import urllib.parse

import boto3

s3 = boto3.client("s3")
DESTINATION_BUCKET = os.environ["DESTINATION_BUCKET"]


def lambda_handler(event, context):
    for sqs_record in event.get("Records", []):
        body = json.loads(sqs_record["body"])

        for s3_record in body.get("Records", []):
            source_bucket = s3_record["s3"]["bucket"]["name"]
            source_key = urllib.parse.unquote_plus(
                s3_record["s3"]["object"]["key"]
            )

            copy_source = {
                "Bucket": source_bucket,
                "Key": source_key,
            }

            s3.copy_object(
                CopySource=copy_source,
                Bucket=DESTINATION_BUCKET,
                Key=source_key,
            )

            print(
                f"Copied s3://{source_bucket}/{source_key} "
                f"to s3://{DESTINATION_BUCKET}/{source_key}"
            )

    return {"statusCode": 200, "body": "Files copied successfully"}
