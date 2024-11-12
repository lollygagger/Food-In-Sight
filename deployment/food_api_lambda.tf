# Lambda function to call Food APIs for detailed food information.
resource "aws_lambda_function" "food_api_lambda" {
  function_name = "food_api_lambda"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "food_api_lambda.lambda_handler" 
  runtime       = "python3.11" 
    layers = [
    aws_lambda_layer_version.food_api_lambda_layer.arn
  ]
  depends_on = [
    data.archive_file.food_lambda_zip,
    aws_lambda_layer_version.food_api_lambda_layer
  ]

  filename = data.archive_file.food_lambda_zip.output_path

  environment {
    variables = {
      FOOD_DATA_API_KEY = "1IBBdfpfJvI77K7gPalVETD69qtXOVRt0JHTg8Wa"
    }
  }
}



#Zipped Python Lambda / Dependencies

# Archive Lambda code if not already zipped
data "archive_file" "food_lambda_zip" {
  type        = "zip"
  source_file = "lambda/food_api_lambda.py"
  output_path = "zipped/food_api_lambda.zip"
}

# Create Dependencies File
resource "null_resource" "install_food_api_lambda_layer_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r lambda/food_api_lambda_requirements.txt -t layers/food_api_lambda_layer/python/lib/python3.11/site-packages"
  }
  triggers = {
    trigger = timestamp()
  }
}

# Zip Dependencies
data "archive_file" "food_api_lambda_layer_zip" {
  type        = "zip"
  source_dir  = "layers/food_api_lambda_layer"
  output_path = "zipped/food_api_lambda_layer.zip"
  depends_on = [
    null_resource.install_food_api_lambda_layer_dependencies
  ]
}

# Create lambda layer with dependencies
resource "aws_lambda_layer_version" "food_api_lambda_layer" {
  filename = data.archive_file.food_api_lambda_layer_zip.output_path
  source_code_hash = data.archive_file.food_api_lambda_layer_zip.output_base64sha256
  layer_name = "food_api_layer_dependencies"

  compatible_runtimes = ["python3.11"]
  depends_on = [
    data.archive_file.food_api_lambda_layer_zip
  ]
}



# Permissions

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
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

