provider "aws" {
    region = "us-east-1"
}

locals {
    aws_key = "schwartz514" #CHANGE TO BE YOUR KEY
}

# Lambda

# Create the Lambda function
resource "aws_lambda_function" "user_lambda" {
    function_name = "user_lambda"
    role          = aws_iam_role.lambda_exec.arn
    handler       = "user-processing.lambda_handler"  # Ensure the handler matches your Python file's handler function
    runtime       = "python3.11"  # Set to your desired Python runtime
    filename      = data.archive_file.lambda_zip.output_path
}

resource "aws_iam_role" "lambda_exec" {
    name = "serverless_lambda"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
            Service = "lambda.amazonaws.com"
        }
        }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB Table
resource "aws_dynamodb_table" "user_table" {
    name            = "Users"
    billing_mode    = "PROVISIONED"
    read_capacity   = "1"
    write_capacity  = "1"
    hash_key        = "UserName"

    attribute {
        name = "UserName"
        type = "S"
    }
}

# Create an API Gateway from the Swagger specification
resource "aws_api_gateway_rest_api" "user_api" {
    name        = "UserAPI"
    description = "API Gateway created from Swagger file with Lambda proxy integration"

    body = data.local_file.api_swagger_spec.content
}

resource "aws_api_gateway_resource" "proxy" {
    rest_api_id = "${aws_api_gateway_rest_api.user_api.id}"
    parent_id   = "${aws_api_gateway_rest_api.user_api.root_resource_id}"
    path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
    rest_api_id   = "${aws_api_gateway_rest_api.user_api.id}"
    resource_id   = "${aws_api_gateway_resource.proxy.id}"
    http_method   = "ANY"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
    rest_api_id             = aws_api_gateway_rest_api.user_api.id
    resource_id             = aws_api_gateway_resource.proxy.id
    http_method             = aws_api_gateway_method.proxy.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = aws_lambda_function.user_lambda.invoke_arn
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "user_api_deployment" {
    depends_on = [
        aws_api_gateway_rest_api.user_api
    ]
    rest_api_id = "${aws_api_gateway_rest_api.user_api.id}"
    stage_name  = "prod"  # Adjust stage name as needed
}

# Integrate each Lambda function with API Gateway methods if required
# Automatically set up with Swagger but use these configurations if needed for additional permissions
resource "aws_lambda_permission" "api_gateway_invoke" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.user_lambda.arn
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_api_gateway_rest_api.user_api.execution_arn}/*/*"
}

# Load the Swagger specification from the local file
data "local_file" "api_swagger_spec" {
    filename = "${path.module}/usersApiDoc.yaml"  # Ensure this matches your actual Swagger file path
}

data "template_file" "swagger_with_lambda_arn" {
    template = data.local_file.api_swagger_spec.content
    vars = {
        lambda_arn = aws_lambda_function.user_lambda.arn
    }
}

# Package the Python code as a .zip file for Lambda deployment
data "archive_file" "lambda_zip" {
    type        = "zip"
    source_file = "${path.module}/user-processing.py"  # Ensure this matches the path to your Python file
    output_path = "${path.module}/user-processing.zip"
}