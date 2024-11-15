import json
import os
import requests

def lambda_handler(event, context):
    # Extract the Step Function Payload
    step_function_payload = event.get('Step_Function_Payload', {})
    labels = step_function_payload.get("image_labels", [])
    username = step_function_payload.get("username", "")
    image_url = step_function_payload.get("image_url", "")

    if not labels:
        return {
            "statusCode": 422,
            "body": json.dumps({
                "message": "No Recognition Labels Received",
                "Step_Function_Payload": step_function_payload
            })
        }
    
    most_confident_label = max(labels, key=lambda obj: obj["Confidence"])
    food_name = most_confident_label["Name"]
    
    if not food_name:
        return {
            "statusCode": 422,
            "body": json.dumps({
                "message": "No food name provided.",
                "Step_Function_Payload": step_function_payload
            })
        }
    
    # Add the most confident label's confidence to the payload
    step_function_payload['rekognition_confidence'] = most_confident_label["Confidence"]

    res = request_food_data_central_api(food_name)
    if res['statusCode'] < 200 or res['statusCode'] > 299:
        res = request_open_food_facts_api(food_name)

    # Return Step Function Payload in the response
    res["Step_Function_Payload"] = step_function_payload
    
    return res

def request_food_data_central_api(food_name):
    api_key = os.getenv("FOOD_DATA_API_KEY")
    if not api_key:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "API key not found."})
        }
    
    url = f"https://api.nal.usda.gov/fdc/v1/foods/search?query={food_name}&api_key={api_key}"
    
    try:
        response = requests.get(url)
        response.raise_for_status() 
        data = response.json()
        
        # Get the first item
        food_item = data['foods'][0] 

        return {
            "statusCode": 200,
            "body": json.dumps({"source": "FoodDataCentral", "food_info": food_item})
        }

    except requests.exceptions.RequestException as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        } 

def request_open_food_facts_api(food_name):
    url = f"https://world.openfoodfacts.org/cgi/search.pl?search_terms={food_name}&search_simple=1&action=process&json=1"
    
    try:
        response = requests.get(url)
        response.raise_for_status() 
        data = response.json()

        if 'products' in data and len(data['products']) > 0:
            food_item = data['products'][0]  

            return {
                "statusCode": 200,
                "body": json.dumps({"source": "OpenFoodFacts", "food_info": food_item})
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "No matching food item found in Open Food Facts."})
            }

    except requests.exceptions.RequestException as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
