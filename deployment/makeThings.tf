# Lambda Function
resource "aws_lambda_function" "hello_function2" {
  function_name = "HelloFunction2"
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  # Lambda function code
  filename = "hello_function.zip" # Package your Lambda code as hello_function.zip and place it in the same directory as the Terraform file.

  # IAM Role for Lambda
  role = aws_iam_role.lambda_exec2.arn
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec2" {
  name = "lambda_exec_role2"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_exec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:*",
          "lambda:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


# ================================================================================

# IAM Role for Step Function
resource "aws_iam_role" "step_function_role2" {
  name = "step_function_role2"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for Step Function to Invoke Lambda
resource "aws_iam_role_policy" "step_function_policy" {
  name = "step_function_policy"
  role = aws_iam_role.step_function_role2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "lambda:InvokeFunction"
        Effect = "Allow"
        Resource = aws_lambda_function.hello_function2.arn
      }
    ]
  })
}

# Step Function
resource "aws_sfn_state_machine" "lambda_state_machine2" {
  name     = "LambdaStateMachine2"
  role_arn = aws_iam_role.step_function_role2.arn

  definition = jsonencode({
    StartAt = "HelloState",
    States = {
      HelloState = {
        Type       = "Task",
        Resource   = aws_lambda_function.hello_function2.arn,
        End        = true
      }
    }
  })
}

#======================================================================================


# Create API Gateway REST API
resource "aws_apigatewayv2_api" "step_function_api" {
  name          = "StepFunctionAPI"
  protocol_type = "HTTP"
}

# API Gateway Integration with Step Function
resource "aws_apigatewayv2_integration" "step_function_integration" {
  api_id           = aws_apigatewayv2_api.step_function_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_sfn_state_machine.lambda_state_machine2.arn
  payload_format_version = "2.0"

  credentials_arn = aws_iam_role.apigateway_stepfunction_role.arn
}

# IAM Role for API Gateway to invoke Step Functions
resource "aws_iam_role" "apigateway_stepfunction_role" {
  name = "apigateway_stepfunction_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for API Gateway to invoke Step Functions
resource "aws_iam_role_policy" "apigateway_stepfunction_policy" {
  name = "apigateway_stepfunction_policy"
  role = aws_iam_role.apigateway_stepfunction_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "states:StartExecution"
        Resource = aws_sfn_state_machine.lambda_state_machine2.arn
      }
    ]
  })
}

# Define the Route
resource "aws_apigatewayv2_route" "step_function_route" {
  api_id    = aws_apigatewayv2_api.step_function_api.id
  route_key = "POST /start"  # HTTP POST to /start
  target    = "integrations/${aws_apigatewayv2_integration.step_function_integration.id}"
}

# Deploy the API Stage
resource "aws_apigatewayv2_stage" "step_function_stage" {
  api_id      = aws_apigatewayv2_api.step_function_api.id
  name        = "prod"
  auto_deploy = true
}
