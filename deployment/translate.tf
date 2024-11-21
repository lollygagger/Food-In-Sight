# Define the S3 Bucket to store uploaded files
resource "aws_s3_bucket" "file_upload_bucket" {
  bucket = "translation-files-${uuid()}"
  force_destroy = true
}

data "archive_file" "translate_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/translate_lambda.py"
  output_path = "${path.module}/lambda/translate_lambda.zip"
}

# IAM role for Lambda for S3, Textract, and Translate
resource "aws_iam_role" "translate_lambda_execution_role" {
  name = "LambdaExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for lambda to access everything needed
resource "aws_iam_role_policy" "lambda_policy" {
  name = "LambdaS3TextractTranslatePolicy"
  role = aws_iam_role.translate_lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.file_upload_bucket.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "textract:StartDocumentTextDetection",
          "textract:GetDocumentTextDetection",
          "textract:DetectDocumentText", #For synchronous
          "textract:StartDocumentTextDetection" #For asynchronous
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "translate:TranslateText",
          "translate:TranslateDocument"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "comprehend:DetectDominantLanguage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "process_file_function" {
  function_name = "process_file_function"
  role          = aws_iam_role.translate_lambda_execution_role.arn
  runtime       = "python3.11"

  # These are required for referencing a lambda which is stored locally
  handler         = "translate_lambda.handler"
  filename        = "lambda/translate_lambda.zip" # Must be a zip file
  source_code_hash = data.archive_file.translate_lambda_zip.output_base64sha256 # grab the hash from the zipped file

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.file_upload_bucket.bucket
    }
  }
}

#Pre signed URLS -------------------------------------------------------------------------------------------------------

data "archive_file" "translate_lambda_presign_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/translate_presigned_url.py"
  output_path = "${path.module}/lambda/translate_presigned_url.zip"
}

resource "aws_lambda_function" "generate_translate_presigned_url" {
  function_name = "generateTranslatePresignedUrl" #Using pre-existing role
  role          = aws_iam_role.translate_lambda_execution_role.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.11"
  filename = "lambda/translate_presigned_url.zip"

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.file_upload_bucket.bucket
    }
  }

  source_code_hash = data.archive_file.translate_lambda_presign_zip.output_base64sha256
}


output "s3_bucket_name" {
  value = aws_s3_bucket.file_upload_bucket.bucket
}

