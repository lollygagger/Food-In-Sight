import json
import boto3
import os

textract = boto3.client('textract')
translate = boto3.client('translate')
s3 = boto3.client('s3')

def handler(event, context):
    try:
        # Debugging: Print the received event to CloudWatch Logs
        print("Received event:", json.dumps(event))

        # Get bucket name from environment variable
        bucket_name = os.environ.get('BUCKET_NAME')
        if not bucket_name:
            raise ValueError("Environment variable BUCKET_NAME is not set.")

        # Parse the request body to retrieve the file key
        try:
            body = json.loads(event['body']git)
            file_key = body.get('file_key')
            if not file_key:
                raise ValueError("File key not provided in the request body.")
        except json.JSONDecodeError:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Invalid JSON in request body'})
            }

        # Call Textract to extract text from the image
        try:
            response = textract.detect_text(
                Document={'S3Object': {'Bucket': bucket_name, 'Name': file_key}}
            )
        except textract.exceptions.InvalidS3ObjectException as e:
            print(f"Textract error: {e}")
            return {
                'statusCode': 500,
                'body': json.dumps({'error': 'Textract failed to process the image'})
            }
        except Exception as e:
            print(f"Unexpected Textract error: {e}")
            return {
                'statusCode': 500,
                'body': json.dumps({'error': 'Unexpected error with Textract'})
            }

        # Extract text from Textract response
        extracted_text = ""
        for item in response.get('Blocks', []):
            if item['BlockType'] == 'LINE':
                extracted_text += item.get('Text', '') + '\n'

        if not extracted_text:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'No text found in image'})
            }

        # Call Translate to translate the extracted text into English
        try:
            translated = translate.translate_text(
                Text=extracted_text,
                SourceLanguageCode='auto',
                TargetLanguageCode='en'
            )
            translated_text = translated.get('TranslatedText', '')
        except Exception as e:
            print(f"Translate error: {e}")
            return {
                'statusCode': 500,
                'body': json.dumps({'error': 'Translation service failed'})
            }

        # Return the translated text
        return {
            'statusCode': 200,
            'body': json.dumps({'translated_text': translated_text})
        }

    except Exception as e:
        # Log unexpected errors and return a generic message
        print(f"Unexpected error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
