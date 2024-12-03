import os
import boto3
from botocore.exceptions import ClientError

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.getenv("DYNAMODB_TABLE")

def lambda_handler(event, context):
    """
    Lambda function to handle post-user-creation events.
    Inserts the new user's username into the DynamoDB table only if it doesn't already exist.
    """
    try:
        # Get the DynamoDB table
        table = dynamodb.Table(table_name)

        # Extract the username from the Cognito event
        username = event['userName']

        # Check if the username already exists
        response = table.get_item(
            Key={
                'UserName': username
            }
        )

        if 'Item' in response:
            # Username already exists, do nothing
            print(f"Username '{username}' already exists in the table.")
        else:
            # Insert the username into the DynamoDB table
            table.put_item(
                Item={
                    'UserName': username
                }
            )
            print(f"Successfully added user: {username}")

        return event  # Returning event is required for Cognito triggers
    except KeyError as e:
        print(f"KeyError: Missing required key in the event: {e}")
        raise
    except ClientError as e:
        print(f"ClientError: {e.response['Error']['Message']}")
        raise
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise
