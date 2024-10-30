import boto3
import json
from decimal import Decimal

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Users')

# Custom JSON encoder to handle Decimal objects
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    try:
        # Get the path from the event object
        path = event['path']

        if path == '/user':
            # Handle specific user query by ID
            params = event.get('queryStringParameters', {})
            user_id = params.get('id') if params else None

            if not user_id or not user_id.isdigit():
                raise ValueError("Invalid or missing 'id' query parameter")

            response = table.get_item(Key={'Id': int(user_id)})

            if 'Item' in response:
                return {
                    'statusCode': 200,
                    'body': json.dumps(response['Item'], cls=DecimalEncoder),
                    'headers': {'Content-Type': 'application/json'}
                }
            else:
                return {
                    'statusCode': 404,
                    'body': json.dumps({'message': 'User not found'}),
                    'headers': {'Content-Type': 'application/json'}
                }

        elif path == '/users':
            # Handle request to return all users
            response = table.scan()

            if 'Items' in response:
                return {
                    'statusCode': 200,
                    'body': json.dumps(response['Items'], cls=DecimalEncoder),
                    'headers': {'Content-Type': 'application/json'}
                }
            else:
                return {
                    'statusCode': 404,
                    'body': json.dumps({'message': 'No users found'}),
                    'headers': {'Content-Type': 'application/json'}
                }

        else:
            # Handle invalid paths
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Invalid path'}),
                'headers': {'Content-Type': 'application/json'}
            }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {'Content-Type': 'application/json'}
        }
