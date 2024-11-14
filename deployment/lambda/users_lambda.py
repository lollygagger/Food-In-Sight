import boto3
import json
import os
from decimal import Decimal

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DYNAMODB_TABLE']
table = dynamodb.Table(table_name)

# Custom JSON encoder to handle Decimal objects
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super(DecimalEncoder, self).default(obj)

# Helper function to return consistent API response
def api_response(status_code, message, data=None):
    response = {
        'statusCode': status_code,
        'body': json.dumps({'message': message, 'data': data}, cls=DecimalEncoder) if data else json.dumps({'message': message}),
        'headers': {'Content-Type': 'application/json'}
    }
    return response

# Helper function to get user by UserName
def get_user(user_name):
    return table.get_item(Key={'UserName': user_name})

# Helper function to validate input fields
def validate_fields(fields):
    for field, value in fields.items():
        if not value:
            return f"{field} is required"
    return None

def lambda_handler(event, context):
    try:
        path = event['path']
        http_method = event['httpMethod']

        if path == '/user' and http_method == 'GET':
            # Handle specific user query by username
            params = event.get('queryStringParameters', {})
            user_name = params.get('username')

            if not user_name:
                return api_response(400, "Missing 'username' query parameter")

            response = get_user(user_name)
            if 'Item' in response:
                return api_response(200, "User found", response['Item'])
            return api_response(404, "User not found")

        elif path == '/user' and http_method == 'POST':
            # Handle request to add a new user
            body = json.loads(event.get('body', '{}'))
            user_name = body.get('UserName')
            password = body.get('Password')

            validation_error = validate_fields({'UserName': user_name, 'Password': password})
            if validation_error:
                return api_response(400, validation_error)

            # Check if UserName already exists
            response = get_user(user_name)
            if 'Item' in response:
                return api_response(409, "UserName already exists")

            # Add new user to the table
            table.put_item(Item={'UserName': user_name, 'Password': password})
            return api_response(201, "User created successfully")

        elif path == '/user/diets' and http_method == 'GET':
            # Handle request to get diets of a specified user
            params = event.get('queryStringParameters', {})
            user_name = params.get('username')

            if not user_name:
                return api_response(400, "Missing 'username' query parameter")

            response = get_user(user_name)
            if 'Item' in response and 'Diets' in response['Item']:
                return api_response(200, "Diets found", response['Item']['Diets'])
            elif 'Item' in response:
                return api_response(404, "No diets found for the specified user")
            return api_response(404, "User not found")

        elif path == '/user/diets' and http_method == 'POST':
            # Handle request to add a diet to the specified user
            body = json.loads(event.get('body', '{}'))
            user_name = body.get('UserName')
            new_diet = body.get('Diet')

            validation_error = validate_fields({'UserName': user_name, 'Diet': new_diet})
            if validation_error:
                return api_response(400, validation_error)

            response = get_user(user_name)
            if 'Item' not in response:
                return api_response(404, "User not found")

            current_diets = response['Item'].get('Diets', [])
            if new_diet in current_diets:
                return api_response(409, "Diet already exists for user")

            # Update the Diets list by appending the new diet
            current_diets.append(new_diet)
            table.update_item(
                Key={'UserName': user_name},
                UpdateExpression="SET Diets = :d",
                ExpressionAttributeValues={':d': current_diets}
            )

            return api_response(200, "Diet added successfully")

        elif path == '/user/diets' and http_method == 'DELETE':
            # Handle request to delete a diet from the specified user
            body = json.loads(event.get('body', '{}'))
            user_name = body.get('UserName')
            diet_to_delete = body.get('Diet')

            validation_error = validate_fields({'UserName': user_name, 'Diet': diet_to_delete})
            if validation_error:
                return api_response(400, validation_error)

            response = get_user(user_name)
            if 'Item' not in response:
                return api_response(404, "User not found")

            current_diets = response['Item'].get('Diets', [])
            if diet_to_delete not in current_diets:
                return api_response(404, "Diet not found for user")

            # Remove the diet from the Diets list
            current_diets.remove(diet_to_delete)
            table.update_item(
                Key={'UserName': user_name},
                UpdateExpression="SET Diets = :d",
                ExpressionAttributeValues={':d': current_diets}
            )

            return api_response(200, "Diet deleted successfully")

        elif path == '/users' and http_method == 'GET':
            # Handle request to return all users
            response = table.scan()
            if 'Items' in response:
                return api_response(200, "Users found", response['Items'])
            return api_response(404, "No users found")

        else:
            return api_response(400, "Invalid path or method")

    except Exception as e:
        return api_response(500, f"Internal server error: {str(e)}")
