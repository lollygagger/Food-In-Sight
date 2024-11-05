# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Define local variables
locals {
  aws_key = "JC_AWS_KEY" # Remember to replace this with your actual key if needed
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution_role" {
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

# Attach policies to the role
resource "aws_iam_role_policy_attachment" "lambda_basic_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Archive Lambda code if not already zipped
data "archive_file" "food_lambda_zip" {
  type        = "zip"
  source_file = "../src/lambda/food-api-lambda.py"
  output_path = "${path.module}/food-api-lambda.zip"
}

# Create Lambda function
resource "aws_lambda_function" "food_api_lambda" {
  function_name = "food_api_lambda"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "food-api-lambda.lambda_handler" # Change this if your handler function is named differently
  runtime       = "python3.8" # Update based on your Lambda's Python version

  # Code source (local zip file)
  filename = data.archive_file.food_lambda_zip.output_path

  environment {
    variables = {
      AWS_KEY = local.aws_key
    }
  }
}
