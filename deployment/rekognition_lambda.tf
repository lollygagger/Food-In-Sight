# Lambda Function to send image to Rekognition
resource "aws_lambda_function" "rekognition_lambda" {
  function_name = "RekognitionLambdaFunction"
  handler       = "rekog_lambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.rekognition_lambda_zip.output_path
  role          = aws_iam_role.rekog_lambda_exec_role.arn
  timeout       = 10

  depends_on = [data.archive_file.rekognition_lambda_zip]
}

# Lambda function to start the model
resource "aws_lambda_function" "start_model" {
  function_name = "StartModelFunction"
  handler       = "start_model.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.start_model_zip.output_path
  role          = aws_iam_role.rekog_lambda_exec_role.arn
  timeout       = 90

  depends_on = [data.archive_file.start_model_zip]
}

# Lambda function to stop the model
resource "aws_lambda_function" "stop_model" {
  function_name = "StopModelFunction"
  handler       = "stop_model.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.stop_model_zip.output_path
  role          = aws_iam_role.rekog_lambda_exec_role.arn
  timeout       = 90

  depends_on = [data.archive_file.stop_model_zip]
}

# Archive Lambda code if not already zipped
data "archive_file" "rekognition_lambda_zip" {
  type        = "zip"
  source_file = "lambda/rekog_lambda_function.py"
  output_path = "zipped/rekog_lambda_function.zip"
}

# Archive Lambda code for start model
data "archive_file" "start_model_zip" {
  type        = "zip"
  source_file = "lambda/start_model.py"
  output_path = "zipped/start_model.zip"
}

# Archive Lambda code for stop model
data "archive_file" "stop_model_zip" {
  type        = "zip"
  source_file = "lambda/stop_model.py"
  output_path = "zipped/stop_model.zip"
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

# Archive Lambda Layer (dependencies for Rekognition)
data "archive_file" "rekognition_lambda_layer_zip" {
  type        = "zip"
  source_dir  = "layers/rekognition_lambda_layer"
  output_path = "zipped/rekognition_lambda_layer.zip"
  depends_on = [
    null_resource.install_rekognition_lambda_layer_dependencies
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

# IAM Policy for Rekognition Lambda (with Rekognition and S3 permissions)
resource "aws_iam_role_policy" "rekognition_lambda_policy" {
  name   = "rekognition_lambda_policy"
  role   = aws_iam_role.rekog_lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Custom Rekognition access
      {
        Action = [
          "rekognition:DetectLabels",
          "rekognition:DetectFaces",
          "rekognition:IndexFaces",
          "rekognition:ListFaces",
          "rekognition:DetectCustomLabels",
          "rekognition:CreateProjectVersion",
          "rekognition:StartProjectVersion",
          "rekognition:StopProjectVersion"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:rekognition:us-east-1:559050203586:project/FoodInSight/version/FoodInSight.2024-11-11T12.31.51/1731346311117"
      },
      #General Rekognition access
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
      # S3 image bucket access
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.image_bucket.bucket}/*"
      },
      # Logs access
      {
        Action   = "logs:*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Lambda function to start the model
resource "null_resource" "start_model_trigger" {
  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${aws_lambda_function.start_model.function_name} output.txt"
  }

  depends_on = [aws_lambda_function.start_model]

  # Run this when applying Terraform (creating the resources)
  lifecycle {
    create_before_destroy = true  # Ensure this runs during apply
  }
}

# Lambda function to stop the model
resource "null_resource" "stop_model_trigger" {
  provisioner "local-exec" {
    when    = destroy  # Only during the destroy phase
    command = "aws lambda invoke --function-name ${self.triggers.function_name} output.txt"
  }

  triggers = {
    function_name = aws_lambda_function.stop_model.function_name
  }
}

