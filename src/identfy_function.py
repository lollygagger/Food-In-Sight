import boto3
from decimal import Decimal
import json
import urllib.parse
import io
from PIL import Image, ImageDraw, ImageFont

rekognition = boto3.client('rekognition')
#model = "arn:aws:rekognition:us-east-1:559050203586:project/Food-In-sight/version/Food-In-sight.2024-10-26T02.09.05/1729922945143"

def detect_food(bucket, photo):
    try:
        response = rekognition.detect_labels(
            Image={'S3Object': {'Bucket': bucket, 'Name': photo}},
            MaxLabels=5,
            MinConfidence=90
        )
        ''' For custom model
        #response = rekognition.detect_custom_labels(
            Image={'S3Object': {'Bucket': bucket, 'Name': photo}},
            MaxLabels=5,
            MinConfidence=90,
            ProjectVersionArn=model
        )
        '''
        return response
    except Exception as e:
        print(f"Error in detect_food: {str(e)}")
        return None

def display_image(bucket, photo, response):
    try:
        # Load image from S3 bucket
        s3_connection = boto3.resource('s3')
        s3_object = s3_connection.Object(bucket, photo)
        s3_response = s3_object.get()

        stream = io.BytesIO(s3_response['Body'].read())
        image = Image.open(stream)

        # Ready image to draw bounding boxes on it.
        imgWidth, imgHeight = image.size
        draw = ImageDraw.Draw(image)

        # Load a default font if Arial is unavailable (e.g., on Lambda)
        try:
            fnt = ImageFont.truetype('/Library/Fonts/Arial.ttf', 50)
        except IOError:
            fnt = ImageFont.load_default()

        # Calculate and display bounding boxes for each detected custom label
        for customLabel in response.get('CustomLabels', []):
            if 'Geometry' in customLabel:
                box = customLabel['Geometry']['BoundingBox']
                left = imgWidth * box['Left']
                top = imgHeight * box['Top']
                width = imgWidth * box['Width']
                height = imgHeight * box['Height']

                draw.text((left, top), customLabel['Name'], fill='#00d400', font=fnt)
                points = [
                    (left, top),
                    (left + width, top),
                    (left + width, top + height),
                    (left, top + height),
                    (left, top)
                ]
                draw.line(points, fill='#00d400', width=5)

        return image
    except Exception as e:
        print(f"Error in display_image: {str(e)}")
        return None

def lambda_handler(event, context):
    try:
        bucket = event['Records'][0]['s3']['bucket']['name']
        photo = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
        response = detect_food(bucket, photo)
        
        if response:
            # Uncomment these lines if you want to display the image
            # image = display_image(bucket, photo, response)
            # image.show()
            print("Detection response:", response)
        else:
            print("No response received from detect_food.")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Success')
        }
    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps('Error processing request')
        }
