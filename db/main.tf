provider "aws" {
    region = "us-east-1"
}

locals {
    aws_key = "schwartz514" #CHANGE TO BE YOUR KEY
}

# DYNAMODB DEV
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

# LAMBDA DEV
resource "aws_lambda_function" "user_lambda" {
    function_name = "UserProcessingFunction"
    runtime       = "python3.11"
    handler       = "users_lambda.lambda_handler"
    role          = aws_iam_role.lambda_exec.arn
    filename      = data.archive_file.zip_python.output_path

    environment {
        variables = {
        DYNAMODB_TABLE = aws_dynamodb_table.user_table.name
        }
    }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
    name = "user_lambda_exec_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action    = "sts:AssumeRole"
            Effect    = "Allow"
            Principal = {
            Service = "lambda.amazonaws.com"
            }
        }
        ]
    })
}

# Attach policies to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_policy" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# API GATEWAY DEV
# API Gateway REST API using Swagger
resource "aws_api_gateway_rest_api" "user_api" {
    name        = "UserAPI"
    description = "API Gateway for User Processing"

    body = data.template_file.swagger_with_lambda_arn.rendered
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
    depends_on  = [aws_api_gateway_rest_api.user_api]
    rest_api_id = aws_api_gateway_rest_api.user_api.id
    stage_name  = "prod"
}

# Lambda Permission for API Gateway to invoke Lambda function
resource "aws_lambda_permission" "api_gateway_invoke" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.user_lambda.arn
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_api_gateway_rest_api.user_api.execution_arn}/*/*"
}


# FILES
data "local_file" "api_swagger_spec" {
    filename = "${path.module}/usersApiDoc.yaml"  # Ensure this matches your actual Swagger file path
}

data "template_file" "swagger_with_lambda_arn" {
    template = data.local_file.api_swagger_spec.content
    vars = {
        lambda_arn = aws_lambda_function.user_lambda.arn
    }
}

data "archive_file" "zip_python" {
    type        = "zip"
    source_file = "${path.module}/users_lambda.py"  # Ensure this matches the path to your Python file
    output_path = "${path.module}/users_lambda.zip"
}