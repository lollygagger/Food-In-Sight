# Define the API Gateway REST API
resource "aws_api_gateway_rest_api" "Food-In-Sight-API" {
  name        = "Food-In-Sight-API"
  description = "API Gateway handling the requests for the Food-in-Sight App"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


#Translate -------------------------------------------------------------------------------------------------------------
# Create a resource under the API for uploading files
resource "aws_api_gateway_resource" "file_upload_resource" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  parent_id   = aws_api_gateway_rest_api.Food-In-Sight-API.root_resource_id
  path_part   = "upload"
}

# Define the PUT method for the file upload endpoint
resource "aws_api_gateway_method" "put_upload_method" {
  rest_api_id   = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id   = aws_api_gateway_resource.file_upload_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

# Integrate the PUT method with the Lambda function
resource "aws_api_gateway_integration" "upload_integration" {
  rest_api_id             = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id             = aws_api_gateway_resource.file_upload_resource.id
  http_method             = aws_api_gateway_method.put_upload_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.process_file_function.arn}/invocations"
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_file_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.Food-In-Sight-API.execution_arn}/*/*"
}
#END Translate ---------------------------------------------------------------------------------------------------------

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  depends_on   = [aws_api_gateway_integration.upload_integration]
  rest_api_id  = aws_api_gateway_rest_api.Food-In-Sight-API.id
  stage_name = "prod"
}

output "api_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}/upload"
}
