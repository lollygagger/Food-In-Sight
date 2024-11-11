import json
import boto3

def lambda_handler(event, context):
    rekognition = boto3.client('rekognition')
    
    # Get the S3 image URL from the event input
    s3_url = event.get('image_url', "")
    
    # Check if URL has enough segments
    url_segments = s3_url.split("/")
    if len(url_segments) < 4:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'message': 'Invalid S3 URL format.',
                'provided_url': s3_url
            })
        }
    
    # Parse bucket name and key based on URL format
    if s3_url.startswith("s3://"):
        # Handle s3://bucket-name/path/to/image.jpg
        bucket_name = url_segments[2]
        key = "/".join(url_segments[3:])
    elif "s3.amazonaws.com" in s3_url:
        # Handle https://bucket-name.s3.amazonaws.com/path/to/image.jpg
        bucket_name = url_segments[2].split(".")[0]
        key = "/".join(url_segments[3:])
    else:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'message': 'Unsupported S3 URL format.',
                'provided_url': s3_url
            })
        }
    
    # Call Rekognition to detect labels
    try:
        response = rekognition.detect_labels(
            Image={
                'S3Object': {
                    'Bucket': bucket_name,
                    'Name': key
                }
            },
            MaxLabels=10,
            MinConfidence=70
        )
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error calling Rekognition API',
                'error': str(e)
            })
        }
    
    # Prepare input for Step Function
    step_function_input = {
        'image_labels': response['Labels'],  # Labels from Rekognition
        's3_bucket': bucket_name,
        's3_key': key
    }
    
    # Return response
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Image processed successfully and Step Function triggered.',
            'rekognition_labels': response['Labels']
        })
    }
