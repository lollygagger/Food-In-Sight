import json
import requests
import os

def get_dietary_restrictions(username):
    # Making a call to the Swagger API's diets endpoint
    api_endpoint = os.getenv('API_ENDPOINT')
    try:
        response = requests.get(f"{api_endpoint}user/diets?username={username}")
    
        if response.status_code == 200:
            return response.json()
        else:
            return {}
    except:
        return {}
        

def lambda_handler(event, context):
    body = json.loads(event.get('body', {}))
    # Extract the Step Function Payload
    step_function_payload = event.get('step_function_payload', {})
    username = step_function_payload.get("username", "")
    image_url = step_function_payload.get("image_url", "")
    
    status_code = event.get("statusCode", "")
    
    if status_code == 200:
        # Parse the food information from food_api_lambda.py's response
        food_info = json.loads(event.get("body", {})).get("food_info", {})
        ingredients = food_info.get("ingredients", [])
        allergens = food_info.get("allergens", [])
        
        # Assuming 'username' is passed in the event for the Swagger API call
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
            "body": json.dumps({"currated_user_results": currated_user_results}),
            "step_function_payload" : step_function_payload
        }
    
    message = body.get("message", "")
    return {
        "statusCode": 200,
        "message": f"Unable to determine specific dietary restrictions because {message}",
        "step_function_payload" : step_function_payload
    }
    
# event = {
#   "statusCode": 200,
#   "body": "{\"source\": \"FoodDataCentral\", \"food_info\": {\"fdcId\": 1850717, \"description\": \"BREAD\", \"dataType\": \"Branded\", \"gtinUpc\": \"826846132022\", \"publishedDate\": \"2021-07-29\", \"brandOwner\": \"Bang Brothers Entertainment, Inc\", \"brandName\": \"BOULART\", \"ingredients\": \"UNBLEACHED ENRICHED WHEAT FLOUR (FLOUR, NIACIN, REDUCED IRON, THIAMINE MONONITRATE, RIBOFLAVIN, FOLIC ACID), WATER, SEA SALT, YEAST, MALT.\", \"marketCountry\": \"United States\", \"foodCategory\": \"Breads & Buns\", \"modifiedDate\": \"2018-03-11\", \"dataSource\": \"LI\", \"packageWeight\": \"17.7 oz/500 g\", \"servingSizeUnit\": \"g\", \"servingSize\": 50.0, \"householdServingFullText\": \"0.1 BREAD\", \"tradeChannels\": [\"NO_TRADE_CHANNEL\"], \"allHighlightFields\": \"\", \"score\": 916.1538, \"microbes\": [], \"foodNutrients\": [{\"nutrientId\": 1003, \"nutrientName\": \"Protein\", \"nutrientNumber\": \"203\", \"unitName\": \"G\", \"derivationCode\": \"LCCS\", \"derivationDescription\": \"Calculated from value per serving size measure\", \"derivationId\": 70, \"value\": 8.0, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 600, \"indentLevel\": 1, \"foodNutrientId\": 23601377}, {\"nutrientId\": 1004, \"nutrientName\": \"Total lipid (fat)\", \"nutrientNumber\": \"204\", \"unitName\": \"G\", \"derivationCode\": \"LCCS\", \"derivationDescription\": \"Calculated from value per serving size measure\", \"derivationId\": 70, \"value\": 1.0, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 800, \"indentLevel\": 1, \"foodNutrientId\": 23601378, \"percentDailyValue\": 1}, {\"nutrientId\": 1005, \"nutrientName\": \"Carbohydrate, by difference\", \"nutrientNumber\": \"205\", \"unitName\": \"G\", \"derivationCode\": \"LCCS\", \"derivationDescription\": \"Calculated from value per serving size measure\", \"derivationId\": 70, \"value\": 50.0, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 1110, \"indentLevel\": 2, \"foodNutrientId\": 23601379, \"percentDailyValue\": 8}, {\"nutrientId\": 1008, \"nutrientName\": \"Energy\", \"nutrientNumber\": \"208\", \"unitName\": \"KCAL\", \"derivationCode\": \"LCCS\", \"derivationDescription\": \"Calculated from value per serving size measure\", \"derivationId\": 70, \"value\": 240, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 300, \"indentLevel\": 1, \"foodNutrientId\": 23601380}, {\"nutrientId\": 2000, \"nutrientName\": \"Total Sugars\", \"nutrientNumber\": \"269\", \"unitName\": \"G\", \"derivationCode\": \"LCCS\", \"derivationDescription\": \"Calculated from value per serving size measure\", \"derivationId\": 70, \"value\": 0.0, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 1510, \"indentLevel\": 3, \"foodNutrientId\": 23601381}, {\"nutrientId\": 1079, \"nutrientName\": \"Fiber, total dietary\", \"nutrientNumber\": \"291\", \"unitName\": \"G\", \"derivationCode\": \"LCCS\", \"derivationDescription\": \"Calculated from value per serving size measure\", \"derivationId\": 70, \"value\": 2.0, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 1200, \"indentLevel\": 3, \"foodNutrientId\": 23601382, \"percentDailyValue\": 4}, {\"nutrientId\": 1087, \"nutrientName\": \"Calcium, Ca\", \"nutrientNumber\": \"301\", \"unitName\": \"MG\", \"derivationCode\": \"LCCD\", \"derivationDescription\": \"Calculated from a daily value percentage per serving size measure\", \"derivationId\": 75, \"value\": 0.0, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 5300, \"indentLevel\": 1, \"foodNutrientId\": 23601383, \"percentDailyValue\": 0}, {\"nutrientId\": 1089, \"nutrientName\": \"Iron, Fe\", \"nutrientNumber\": \"303\", \"unitName\": \"MG\", \"derivationCode\": \"LCCD\", \"derivationDescription\": \"Calculated from a daily value percentage per serving size measure\", \"derivationId\": 75, \"value\": 3.6, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 5400, \"indentLevel\": 1, \"foodNutrientId\": 23601384, \"percentDailyValue\": 10}, {\"nutrientId\": 1093, \"nutrientName\": \"Sodium, Na\", \"nutrientNumber\": \"307\", \"unitName\": \"MG\", \"derivationCode\": \"LCCS\", \"derivationDescription\": \"Calculated from value per serving size measure\", \"derivationId\": 70, \"value\": 560, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 5800, \"indentLevel\": 1, \"foodNutrientId\": 23601385, \"percentDailyValue\": 12}, {\"nutrientId\": 1104, \"nutrientName\": \"Vitamin A, IU\", \"nutrientNumber\": \"318\", \"unitName\": \"IU\", \"derivationCode\": \"LCCD\", \"derivationDescription\": \"Calculated from a daily value percentage per serving size measure\", \"derivationId\": 75, \"value\": 0.0, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 7500, \"indentLevel\": 1, \"foodNutrientId\": 23601386, \"percentDailyValue\": 0}, {\"nutrientId\": 1162, \"nutrientName\": \"Vitamin C, total ascorbic acid\", \"nutrientNumber\": \"401\", \"unitName\": \"MG\", \"derivationCode\": \"LCCD\", \"derivationDescription\": \"Calculated from a daily value percentage per serving size measure\", \"derivationId\": 75, \"value\": 0.0, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 6300, \"indentLevel\": 1, \"foodNutrientId\": 23601387, \"percentDailyValue\": 0}, {\"nutrientId\": 1253, \"nutrientName\": \"Cholesterol\", \"nutrientNumber\": \"601\", \"unitName\": \"MG\", \"derivationCode\": \"LCCD\", \"derivationDescription\": \"Calculated from a daily value percentage per serving size measure\", \"derivationId\": 75, \"value\": 0.0, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 15700, \"indentLevel\": 1, \"foodNutrientId\": 23601388, \"percentDailyValue\": 0}, {\"nutrientId\": 1257, \"nutrientName\": \"Fatty acids, total trans\", \"nutrientNumber\": \"605\", \"unitName\": \"G\", \"derivationCode\": \"LCCS\", \"derivationDescription\": \"Calculated from value per serving size measure\", \"derivationId\": 70, \"value\": 0.0, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 15400, \"indentLevel\": 1, \"foodNutrientId\": 23601389}, {\"nutrientId\": 1258, \"nutrientName\": \"Fatty acids, total saturated\", \"nutrientNumber\": \"606\", \"unitName\": \"G\", \"derivationCode\": \"LCCD\", \"derivationDescription\": \"Calculated from a daily value percentage per serving size measure\", \"derivationId\": 75, \"value\": 0.0, \"foodNutrientSourceId\": 9, \"foodNutrientSourceCode\": \"12\", \"foodNutrientSourceDescription\": \"Manufacturer's analytical; partial documentation\", \"rank\": 9700, \"indentLevel\": 1, \"foodNutrientId\": 23601390, \"percentDailyValue\": 0}], \"finalFoodInputFoods\": [], \"foodMeasures\": [], \"foodAttributes\": [], \"foodAttributeTypes\": [], \"foodVersionIds\": []}}",
#   "step_function_payload": {
#     "image_url": "s3://imagebucket-293bc94f-e72e-a9f1-7bb9-4c38e99081c1/images/dd4a502d-bc67-49c1-9621-ef7490e5113a.jpg",
#     "username": "Jacob Canedy",
#     "rekognition_confidence": 97.21846771240234
#   }
# }
# res = lambda_handler(event, {})
# print()