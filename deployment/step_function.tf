
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
        Resource = [
          aws_lambda_function.rekognition_lambda.arn,
        ]
      }
    ]
  })
}

# Step Function
resource "aws_sfn_state_machine" "lambda_state_machine2" {
  name     = "LambdaStateMachine2"
  role_arn = aws_iam_role.step_function_role2.arn

  definition = jsonencode({
    StartAt = "InvokeRekognitionLambda",
    States = {
      InvokeRekognitionLambda = {
        Type       = "Task",
        Resource   = aws_lambda_function.rekognition_lambda.arn,
        Parameters = {
          "Payload": {
            "image_url.$": "$.image_url"  # Use ".$" to pass the image_url from input dynamically
          }
        },
        End        = true
      }
    }
    #States = {
    #   InvokeRekognitionLambda = {
    #     Type       = "Task",
    #     Resource   = aws_lambda_function.rekognition_lambda.arn,
    #     Parameters = {
    #       image_url = "$.image_url"
    #     },
    #     Next = "InvokeAnotherLambda"  # Next state after Rekognition
    #   },
    #   InvokeAnotherLambda = {
    #     Type       = "Task",
    #     Resource   = aws_lambda_function.another_lambda.arn,
    #     Parameters = {
    #       data = "$.rekognition_data"
    #     },
    #     End        = true
    #   }
    # }
  })
}