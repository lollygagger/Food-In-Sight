import json
import boto3


def lambda_handler(event, context):
    rekognition = boto3.client('rekognition')

    # Get the S3 image URL from the event input
    s3_url = event.get('Payload', {}).get('image_url', "")

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

    # Call Rekognition to detect custom labels
    try:
        response = rekognition.detect_custom_labels(
            Image={
                'S3Object': {
                    'Bucket': bucket_name,
                    'Name': key
                }
            },
            MaxResults=10,
            MinConfidence=70,
            ProjectVersionArn="arn:aws:rekognition:us-east-1:559050203586:project/FoodInSight/version/FoodInSight.2024-11-11T12.31.51/1731346311117"
        )

        # If no custom labels are found, fall back to regular Rekognition
        if not response['CustomLabels']:
            response = rekognition.detect_labels(
                Image={
                    'S3Object': {
                        'Bucket': bucket_name,
                        'Name': key
                    }
                },
                MaxLabels=10,
                MinConfidence=70,
            )
            custom_labels = response['Labels']
        else:
            custom_labels = response['CustomLabels']

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
        'image_labels': custom_labels,  # Labels from Rekognition
        's3_bucket': bucket_name,
        's3_key': key
    }

    # Return response
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Image processed successfully and Step Function triggered.',
            'rekognition_labels': custom_labels
        })
    }
