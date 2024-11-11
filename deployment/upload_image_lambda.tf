
# Lambda Function to handle image upload to S3
resource "aws_lambda_function" "upload_image_lambda" {
  function_name = "UploadImageLambdaFunction"
  handler       = "upload_image_function.lambda_handler"
  runtime       = "python3.12"
  filename      = "upload_image_function.zip"
  role          = aws_iam_role.upload_image_lambda_exec_role.arn
  timeout       = 10

  environment {
    variables = {
      STEP_FUNCTION_ARN = aws_sfn_state_machine.lambda_state_machine2.arn,
      IMAGE_BUCKET_NAME = aws_s3_bucket.image_bucket.bucket
    }
  }
}


# IAM Role for Image Upload Lambda
resource "aws_iam_role" "upload_image_lambda_exec_role" {
  name = "upload_image_lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# IAM Policy for Image Upload Lambda
resource "aws_iam_role_policy" "upload_image_lambda_policy" {
  name   = "upload_image_lambda_policy"
  role   = aws_iam_role.upload_image_lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.image_bucket.arn}/*"
      },
       {
        Action   = "states:StartExecution"
        Effect   = "Allow"
        Resource = aws_sfn_state_machine.lambda_state_machine2.arn
      },
      {
        Action   = "logs:*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
