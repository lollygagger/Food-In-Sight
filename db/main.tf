provider "aws" {
    region = "us-east-1"
}

locals {
    aws_key = "schwartz514" #CHANGE TO BE YOUR KEY
}

# Lambda
resource "aws_iam_role" "lambda_role" {
    name = "lambda_execution_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Principal = {
            Service = "lambda.amazonaws.com"
            }
        }
        ]
    })
}

# Attach a policy to the role (add any specific permissions as needed)
resource "aws_iam_policy_attachment" "lambda_policy" {
    name       = "lambda_policy_attachment"
    roles      = [aws_iam_role.lambda_role.name]
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Package the Python code as a .zip file for Lambda deployment
data "archive_file" "lambda_zip" {
    type        = "zip"
    source_file = "${path.module}/user-processing.py"  # Ensure this matches the path to your Python file
    output_path = "${path.module}/user-processing.zip"
}

# Create the Lambda function
resource "aws_lambda_function" "user_processing_lambda" {
    function_name = "user_processing_lambda"
    role          = aws_iam_role.lambda_role.arn
    handler       = "user-processing.lambda_handler"  # Ensure the handler matches your Python file's handler function
    runtime       = "python3.11"  # Set to your desired Python runtime
    filename      = data.archive_file.lambda_zip.output_path
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