
# Lambda to determine user restrictions on a food item
resource "aws_lambda_function" "determine_user_restrictions_lambda" {  
  function_name = "determine_user_restrictions_lambda"                 
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "determine_user_restrictions_lambda.lambda_handler"  
  runtime       = "python3.11"
  depends_on    = [data.archive_file.determine_user_restrictions_lambda_zip]

  filename = data.archive_file.determine_user_restrictions_lambda_zip.output_path  
}

#Zipped Python Lambda / Dependencies
data "archive_file" "determine_user_restrictions_lambda_zip" {
  type        = "zip"
  source_file = "lambda/determine_user_restrictions_lambda.py"  
  output_path = "zipped/determine_user_restrictions_lambda.zip"        
}

# Create Dependencies File
resource "null_resource" "install_determine_user_restrictions_lambda_layer_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r lambda/determine_user_restrictions_lambda_requirements.txt -t layers/determine_user_restrictions_lambda_layer/python/lib/python3.11/site-packages"
  }
  triggers = {
    trigger = timestamp()
  }
}

# Zip Dependencies
data "archive_file" "determine_user_restrictions_lambda_layer_zip" {
  type        = "zip"
  source_dir  = "layers/determine_user_restrictions_lambda_layer"
  output_path = "zipped/determine_user_restrictions_lambda_layer.zip"
  depends_on = [
    null_resource.install_determine_user_restrictions_lambda_layer_dependencies
  ]
}

# Create lambda layer with dependencies
resource "aws_lambda_layer_version" "determine_user_restrictions_lambda_layer" {
  filename = data.archive_file.determine_user_restrictions_lambda_layer_zip.output_path
  source_code_hash = data.archive_file.determine_user_restrictions_lambda_layer_zip.output_base64sha256
  layer_name = "determine_user_restrictions_lambda_layer_dependencies"

  compatible_runtimes = ["python3.11"]
  depends_on = [
    data.archive_file.determine_user_restrictions_lambda_layer_zip
  ]
}
