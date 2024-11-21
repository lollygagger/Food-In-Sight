import json
import os
import requests

def lambda_handler(event, context):
    # Extract the Step Function Payload
    body = json.loads(event.get('body', {}))
    step_function_payload = body.get('step_function_payload', {})
    labels = body.get("rekognition_labels", [])
    username = step_function_payload.get("username", "")
    image_url = step_function_payload.get("image_url", "")

    if not labels:
        return {
            "statusCode": 422,
            "body": json.dumps({
                "message": "No Recognition Labels Received",
                "step_function_payload": step_function_payload
            })
        }

    # Filter out obviously bad labels like 'Food'
    specific_labels = [label for label in labels if label["Name"].lower() != "food"]
    
    #Choose most confident specific label
    most_confident_label = labels[0] if len(labels) == 1 else max(labels, key=lambda obj: obj["Confidence"])
    food_name = most_confident_label["Name"]
    
    if not food_name:
        return {
            "statusCode": 422,
            "body": json.dumps({
                "message": "No food name provided.",
                "step_function_payload": step_function_payload
            })
        }
    
    # Add the most confident label's confidence to the payload
    step_function_payload['rekognition_confidence'] = most_confident_label["Confidence"]

    res = request_open_food_facts_api(food_name)
    if res['statusCode'] < 200 or res['statusCode'] > 299:
        res = request_food_data_central_api(food_name)

    # Return Step Function Payload in the response
    res["step_function_payload"] = step_function_payload

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
        
        # Right now we just get the first item... There should be a way to make it more accurate, if not we could average out key metrics for food on first 100 items
        if 'foods' in data and data['foods']:
            food_item = data['foods'][0]  # Get the first item if available

            return {
                "statusCode": 200,
                "body": json.dumps({"source": "FoodDataCentral", "food_info": food_item})
            }
        else:
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "No matching food item found in FoodDataCentral."})
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
