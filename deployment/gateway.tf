# Define the API Gateway REST API
resource "aws_api_gateway_rest_api" "file_upload_api" {
  name        = "Food-In-Sight"
  description = "API for uploading files to S3 and processing with Textract and Translate"
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "file_upload_deployment" {
  rest_api_id = aws_api_gateway_rest_api.file_upload_api.id
  stage_name  = "prod"
}

#TRANSLATE -------------------------------------------------------------------------------------------------------------

# Create a resource under the API for uploading files
resource "aws_api_gateway_resource" "file_upload_resource" {
  rest_api_id = aws_api_gateway_rest_api.file_upload_api.id
  parent_id   = aws_api_gateway_rest_api.file_upload_api.root_resource_id
  path_part   = "upload"
}

# Define the PUT method for the file upload endpoint
resource "aws_api_gateway_method" "put_upload_method" {
  rest_api_id   = aws_api_gateway_rest_api.file_upload_api.id
  resource_id   = aws_api_gateway_resource.file_upload_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

# Integrate the PUT method with the Lambda function
resource "aws_api_gateway_integration" "upload_integration" {
  rest_api_id             = aws_api_gateway_rest_api.file_upload_api.id
  resource_id             = aws_api_gateway_resource.file_upload_resource.id
  http_method             = aws_api_gateway_method.put_upload_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.process_file_function.arn}/invocations"
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_file_function.function_name
  principal     = "apigateway.amazonaws.com"
}

output "api_url" {
  value = "${aws_api_gateway_deployment.file_upload_deployment.invoke_url}/upload"
}

#END Translate ---------------------------------------------------------------------------------------------------------