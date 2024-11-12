data "archive_file" "determine_user_restrictions_lambda_zip" {
  type        = "zip"
  source_file = "lambda/determine_user_restrictions_lambda.py"  
  output_path = "zipped/determine_user_restrictions_lambda.zip"        
}

resource "aws_lambda_function" "determine_user_restrictions_lambda" {  
  function_name = "determine_user_restrictions_lambda"                 
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "determine_user_restrictions_lambda.lambda_handler"  
  runtime       = "python3.11"
  depends_on    = [data.archive_file.determine_user_restrictions_lambda_zip]

  filename = data.archive_file.determine_user_restrictions_lambda_zip.output_path  
}