# Lambda Function
resource "aws_lambda_function" "hello_function" {
  function_name = "HelloFunction"
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  # Lambda function code
  filename = "hello_function.zip" # Package your Lambda code as hello_function.zip and place it in the same directory as the Terraform file.

  # IAM Role for Lambda
  role = aws_iam_role.lambda_exec.arn
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
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
  role   = aws_iam_role.lambda_exec.id
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
resource "aws_iam_role" "step_function_role" {
  name = "step_function_role"
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
  role = aws_iam_role.step_function_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "lambda:InvokeFunction"
        Effect = "Allow"
        Resource = aws_lambda_function.hello_function.arn
      }
    ]
  })
}

# Step Function
resource "aws_sfn_state_machine" "lambda_state_machine" {
  name     = "LambdaStateMachine"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    StartAt = "HelloState",
    States = {
      HelloState = {
        Type       = "Task",
        Resource   = aws_lambda_function.hello_function.arn,
        End        = true
      }
    }
  })
}
