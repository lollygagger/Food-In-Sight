import json
import requests

def get_dietary_restrictions(username):
    # Making a call to the Swagger API's diets endpoint
    response = requests.get(f"https://5cvrxwcpog.execute-api.us-east-1.amazonaws.com/prod/user/diets?username={username}")
    
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Failed to get dietary restrictions: {response.status_code}")
        return {}

def lambda_handler(event, context):
    status_code = event.get("statusCode", "")
    
    if status_code == 200:
        # Parse the food information from food_api_lambda.py's response
        food_info = json.loads(event.get("body", {})).get("food_info", {})
        ingredients = food_info.get("ingredients", [])
        allergens = food_info.get("allergens", [])
        
        # Assuming 'username' is passed in the event for the Swagger API call
        username = event.get("username", "default_user")
        diet_restrictions = get_dietary_restrictions(username)
        
        # Analyzing and comparing dietary restrictions
        flagged_items = {
            "restricted_ingredients": [],
            "restricted_allergens": []
        }
        
        for ingredient in ingredients:
            if ingredient in diet_restrictions.get("restricted_ingredients", []):
                flagged_items["restricted_ingredients"].append(ingredient)
        
        for allergen in allergens:
            if allergen in diet_restrictions.get("restricted_allergens", []):
                flagged_items["restricted_allergens"].append(allergen)
        
        food_insight = {
            "flagged_items": flagged_items,
            "diet_restrictions": diet_restrictions
        }
        
        currated_user_results = {
            "food_info": food_info,
            "food_insight": food_insight
        }
        
        return {
            "statusCode": 200,
            "body": json.dumps({"currated_user_results": currated_user_results})
        }
    
    return {
        "statusCode": 400,
        "body": json.dumps({"error": "Unable to determine food item"})
    }