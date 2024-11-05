import json
import os
import requests

def lambda_handler(event, context):
    # Get the FoodData Central API key from environment variables
    api_key = os.getenv("FOOD_DATA_API_KEY")
    if not api_key:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "API key not found."})
        }

    # Get the search term from the event (defaults to "apple" if not provided)
    food_name = event.get("queryStringParameters", {}).get("food_name", "apple")

    # FoodData Central API endpoint for search
    url = f"https://api.nal.usda.gov/fdc/v1/foods/search?query={food_name}&api_key={api_key}"

    try:
        # Make the API request
        response = requests.get(url)
        response.raise_for_status()  # Raise error if request fails
        data = response.json()

        # Return the JSON response from the API
        return {
            "statusCode": 200,
            "body": json.dumps(data)
        }

    except requests.exceptions.RequestException as e:
        # Handle any errors from the API request
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

