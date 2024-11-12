
# Lambda Function to send image to rekognition
resource "aws_lambda_function" "rekognition_lambda" {
  function_name = "RekognitionLambdaFunction"
  handler       = "rekog_lambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = "rekog_lambda_function.zip"  # Ensure this file is present in the same directory
  role          = aws_iam_role.rekog_lambda_exec_role.arn
  timeout       = 10
}

# IAM Role for Lambda
resource "aws_iam_role" "rekog_lambda_exec_role" {
  name = "rekognition_lambda_exec_role"
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
resource "aws_iam_role_policy" "rekognition_lambda_policy" {
  name   = "rekognition_lambda_policy"
  role   = aws_iam_role.rekog_lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rekognition:DetectLabels",
          "rekognition:DetectFaces",
          "rekognition:IndexFaces",
          "rekognition:ListFaces"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.image_bucket.bucket}/*"
      },
      {
        Action   = "logs:*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
