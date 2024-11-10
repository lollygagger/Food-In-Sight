import json
import boto3
import os

textract = boto3.client('textract')
translate = boto3.client('translate')
s3 = boto3.client('s3')

def handler(event, context):
    # Get the file uploaded to S3
    body = json.loads(event['body'])
    file_key = body['file_key']
    bucket_name = os.environ['BUCKET_NAME']

    # Call Textract to extract text from the image
    response = textract.detect_text(
        Document={'S3Object': {'Bucket': bucket_name, 'Name': file_key}}
    )

    # Extract the text from Textract response
    extracted_text = ""
    for item in response['Blocks']:
        if item['BlockType'] == 'LINE':
            extracted_text += item['Text'] + '\n'

    # Call Translate to translate the extracted text into English
    translated = translate.translate_text(
        Text=extracted_text,
        SourceLanguageCode='auto',
        TargetLanguageCode='en'
    )

    translated_text = translated['TranslatedText']

    # Return the translated text to API Gateway
    return {
        'statusCode': 200,
        'body': json.dumps({'translated_text': translated_text})
    }
