import json
import boto3
import os
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def lambda_handler(event, context):
    try:
        # Get the path and HTTP method
        path = event['path']
        http_method = event['httpMethod']
        query_parameters = event.get('queryStringParameters', {})

        # Only handle GET requests
        if http_method != 'GET':
            return {
                'statusCode': 405,
                'headers': {
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Method not allowed'})
            }

        # Route the request based on the path
        if path == '/diets':
            return get_all_diets()
        elif path == '/diet':
            return get_diet_by_restriction(query_parameters)
        elif path == '/diet/ingredients':
            return get_diet_ingredients(query_parameters)
        else:
            return {
                'statusCode': 404,
                'headers': {
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Path not found'})
            }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }

def get_all_diets():
    """Get all diets from the table"""
    response = table.scan()
    items = response.get('Items', [])
    
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(items)
    }

def get_diet_by_restriction(query_params):
    """Get a specific diet by restriction"""
    if not query_params or 'restriction' not in query_params:
        return {
            'statusCode': 400,
            'headers': {
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'restriction parameter is required'})
        }

    restriction = query_params['restriction']
    response = table.get_item(
        Key={
            'Restriction': restriction
        }
    )
    
    item = response.get('Item')
    if not item:
        return {
            'statusCode': 404,
            'headers': {
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': f'Diet with restriction {restriction} not found'})
        }

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(item)
    }

def get_diet_ingredients(query_params):
    """Get ingredients for a specific diet"""
    if not query_params or 'restriction' not in query_params:
        return {
            'statusCode': 400,
            'headers': {
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'restriction parameter is required'})
        }

    restriction = query_params['restriction']
    response = table.get_item(
        Key={
            'Restriction': restriction
        }
    )
    
    item = response.get('Item')
    if not item:
        return {
            'statusCode': 404,
            'headers': {
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': f'Diet with restriction {restriction} not found'})
        }

    # Return only the ingredients
    ingredients = item.get('Ingredients', [])
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'ingredients': ingredients})
    }
