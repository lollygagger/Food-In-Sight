import json
import boto3
from base64 import b64decode
import os
import uuid

def is_base64(sb):
    # Check if the string is a valid Base64 string
    try:
        if isinstance(sb, str):
            sb_bytes = bytes(sb, 'utf-8')
        elif isinstance(sb, bytes):
            sb_bytes = sb
        else:
            return False
        return b64decode(sb_bytes, validate=True) is not None
    except Exception:
        return False

def lambda_handler(event, context):
    if 'body' not in event:
        return {
            "statusCode": 400,
            "body": json.dumps("Request is missing 'body'")
        }

    try:
        body = json.loads(event['body'])
    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "body": json.dumps("Invalid JSON format in 'body'")
        }

    image_data = body.get("image_data")
    if not image_data:
        return {
            "statusCode": 400,
            "body": json.dumps("Image data is missing in 'body'")
        }

    # Validate if image_data is a properly formatted Base64 string
    if not is_base64(image_data):
        return {
            "statusCode": 400,
            "body": json.dumps("Invalid Base64 format for image data")
        }

    try:
        # Decode Base64 image data
        image_bytes = b64decode(image_data)
    except Exception as e:
        return {
            "statusCode": 400,
            "body": json.dumps(f"Error decoding Base64 image data: {str(e)}")
        }

    # Upload the image to S3
    s3 = boto3.client('s3')
    bucket_name = os.environ.get("IMAGE_BUCKET_NAME")
    if not bucket_name:
        return {
            "statusCode": 500,
            "body": json.dumps("S3 bucket name is not configured in environment variables")
        }

    # Create a unique file name using UUID
    file_name = f"images/{uuid.uuid4()}.jpg"
    
    try:
        # Upload the image to S3
        s3.put_object(Bucket=bucket_name, Key=file_name, Body=image_bytes, ContentType='image/jpeg')
        image_url = f"s3://{bucket_name}/{file_name}"
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error uploading image to S3: {str(e)}")
        }

    # Trigger Step Function
    step_functions_client = boto3.client('stepfunctions')
    
    # Get Step Function ARN from environment variable
    step_function_arn = os.environ.get("STEP_FUNCTION_ARN")
    if not step_function_arn:
        return {
            "statusCode": 500,
            "body": json.dumps("Step Function ARN is not configured in environment variables")
        }

    # Prepare the input for the Step Function (you can modify this based on your need)
    step_function_input = {
        "image_url": image_url  # pass the S3 URL of the uploaded image
    }

    # Trigger Step Function execution
    try:
        step_response = step_functions_client.start_execution(
            stateMachineArn=step_function_arn,
            input=json.dumps(step_function_input)
        )
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Image uploaded to S3 and Step Function triggered.",
                "image_url": image_url,
                "step_function_execution_arn": step_response['executionArn']
            })
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error triggering Step Function: {str(e)}")
        }
