
# Lambda Function to send image to rekognition
resource "aws_lambda_function" "rekognition_lambda" {
  function_name = "RekognitionLambdaFunction"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = "rekog_lambda_function.zip"  # Ensure this file is present in the same directory
  role          = aws_iam_role.rekog_lambda_exec_role.arn
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



# Lambda Function to handle image upload to S3
resource "aws_lambda_function" "upload_image_lambda" {
  function_name = "UploadImageLambdaFunction"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = "upload_image_lambda.zip"
  role          = aws_iam_role.upload_image_lambda_exec_role.arn

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
        },
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"  # This allows API Gateway to assume the role.
        }
      }
      }
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
        Resource = "arn:aws:s3:::${aws_s3_bucket.image_bucket.bucket}/*"
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
          image_url = "$.image_url"
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


# API Gateway and Integration
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "my-api"
  description = "My API Gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "mypath"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.root.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration with Step Function
resource "aws_api_gateway_integration" "step_function_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:states:action/StartExecution"
  credentials             = aws_iam_role.apigateway_role.arn

  request_templates = {
    "application/json" = <<EOF
    {
      "input": "$util.escapeJavaScript($input.body)",
      "stateMachineArn": "${aws_sfn_state_machine.lambda_state_machine2.arn}",
      "name": "Execution-$context.requestId"
    }
    EOF
  }
}

# Method and Integration Responses
resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.step_function_integration
  ]
}


#API resources for image upload
resource "aws_api_gateway_resource" "upload_image" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "uploadimage"
}

resource "aws_api_gateway_method" "upload_image_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.upload_image.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "upload_image_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.upload_image.id
  http_method             = aws_api_gateway_method.upload_image_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.upload_image_lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "upload_image_response" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.upload_image.id
  http_method = aws_api_gateway_method.upload_image_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "upload_image_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.upload_image.id
  http_method = aws_api_gateway_method.upload_image_method.http_method
  status_code = aws_api_gateway_method_response.upload_image_response.status_code

  depends_on = [
    aws_api_gateway_integration.upload_image_integration
  ]
}


# Deploy API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.step_function_integration,
    aws_api_gateway_method_response.proxy,
  ]

  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = "dev"
}

# API Gateway IAM Role for Step Function
resource "aws_iam_role" "apigateway_role" {
  name = "apigateway_step_function_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "apigateway_policy" {
  name = "apigateway_step_function_policy"
  role = aws_iam_role.apigateway_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "states:StartExecution"
        Effect = "Allow"
        Resource = aws_sfn_state_machine.lambda_state_machine2.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_lambda_invoke_policy" {
  name   = "api_gateway_lambda_invoke_policy"
  role   = aws_iam_role.apigateway_role.id  # Ensure API Gateway role is correctly set here.
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = aws_lambda_function.upload_image_lambda.arn
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_apigateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_image_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}





resource "aws_s3_bucket" "image_bucket" {
  bucket = "imagebucketuniquename123123089658970"
}

resource "aws_s3_bucket_ownership_controls" "image_bucket_controls" {
  bucket = aws_s3_bucket.image_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "image_bucket_ac1" {
  depends_on = [aws_s3_bucket_ownership_controls.image_bucket_controls]

  bucket = aws_s3_bucket.image_bucket.id
  acl    = "private"
}