# Lambda Function to send image to rekognition
resource "aws_lambda_function" "rekognition_lambda" {
  function_name = "RekognitionLambdaFunction"
  handler       = "rekog_lambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.rekognition_lambda_zip.output_path
  role          = aws_iam_role.rekog_lambda_exec_role.arn
  timeout       = 10

  depends_on = [ data.archive_file.rekognition_lambda_zip ]
}

#Zipped Python Lambda / Dependencies

# Archive Lambda code if not already zipped
data "archive_file" "rekognition_lambda_zip" {
  type        = "zip"
  source_file = "lambda/rekog_lambda_function.py"
  output_path = "zipped/rekog_lambda_function.zip"
}

# Create Dependencies File
resource "null_resource" "install_rekognition_lambda_layer_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r lambda/rekog_lambda_function_requirements.txt -t layers/rekognition_lambda_layer/python/lib/python3.11/site-packages"
  }
  triggers = {
    trigger = timestamp()
  }
}

# Zip Dependencies
data "archive_file" "rekognition_lambda_layer_zip" {
  type        = "zip"
  source_dir  = "layers/rekognition_lambda_layer"
  output_path = "zipped/rekognition_lambda_layer.zip"
  depends_on = [
    null_resource.install_food_api_lambda_layer_dependencies
  ]
}

# Create lambda layer with dependencies
resource "aws_lambda_layer_version" "rekognition_lambda_layer" {
  filename = data.archive_file.rekognition_lambda_layer_zip.output_path
  source_code_hash = data.archive_file.rekognition_lambda_layer_zip.output_base64sha256
  layer_name = "food_api_layer_dependencies"

  compatible_runtimes = ["python3.12"]
  depends_on = [
    data.archive_file.rekognition_lambda_layer_zip
  ]
}


# Permissions

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
      #rekognition access
      {
        Action = [
          "rekognition:DetectLabels",
          "rekognition:DetectFaces",
          "rekognition:IndexFaces",
          "rekognition:ListFaces"
        ]
        Effect   = "Allow"
        Resource = "*" #TODO specify?
      },
      #image bucket
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
