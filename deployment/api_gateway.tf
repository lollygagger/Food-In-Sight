
# API Gateway and Integration
resource "aws_api_gateway_rest_api" "Food-In-Sight-API" {
  name        = "Food-In-Sight-API"
  description = "API Gateway handling the requests for the Food-in-Sight App"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


#API resources for image upload
resource "aws_api_gateway_resource" "upload_image" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  parent_id   = aws_api_gateway_rest_api.Food-In-Sight-API.root_resource_id
  path_part   = "uploadimage"
}

#API resources for image upload...
resource "aws_api_gateway_method" "upload_image_method" {
  rest_api_id   = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id   = aws_api_gateway_resource.upload_image.id
  http_method   = "POST"
  authorization = "NONE"
}

#API resources for image upload...
resource "aws_api_gateway_integration" "upload_image_integration" {
  rest_api_id             = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id             = aws_api_gateway_resource.upload_image.id
  http_method             = aws_api_gateway_method.upload_image_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.upload_image_lambda.invoke_arn
}

#API resources for image upload...
resource "aws_api_gateway_method_response" "upload_image_response" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id = aws_api_gateway_resource.upload_image.id
  http_method = aws_api_gateway_method.upload_image_method.http_method
  status_code = "200"
}

#API resources for image upload...
resource "aws_api_gateway_integration_response" "upload_image_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id = aws_api_gateway_resource.upload_image.id
  http_method = aws_api_gateway_method.upload_image_method.http_method
  status_code = aws_api_gateway_method_response.upload_image_response.status_code

  depends_on = [
    aws_api_gateway_integration.upload_image_integration
  ]
}

#Translate -------------------------------------------------------------------------------------------------------------
# Create a resource under the API for uploading files
resource "aws_api_gateway_resource" "file_upload_resource" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  parent_id   = aws_api_gateway_rest_api.Food-In-Sight-API.root_resource_id
  path_part   = "translate"
}

# Define the PUT method for the file upload endpoint
resource "aws_api_gateway_method" "put_upload_method" {
  rest_api_id   = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id   = aws_api_gateway_resource.file_upload_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

# Allow API gateway to call POST method on the Lambda function for translate
resource "aws_api_gateway_integration" "upload_integration" {
  rest_api_id             = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id             = aws_api_gateway_resource.file_upload_resource.id
  http_method             = aws_api_gateway_method.put_upload_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.process_file_function.arn}/invocations"
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_file_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.Food-In-Sight-API.execution_arn}/*/*"
}
#END Translate ---------------------------------------------------------------------------------------------------------

#Translate S3 Signed URL -----------------------------------------------------------------------------------------------

resource "aws_api_gateway_resource" "translate_presigned_url" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  parent_id   = aws_api_gateway_rest_api.Food-In-Sight-API.root_resource_id
  path_part   = "presign-translate"
}

resource "aws_api_gateway_method" "get_translate_presigned_url" {
  rest_api_id   = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id   = aws_api_gateway_resource.translate_presigned_url.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "translate_signed_integration" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id = aws_api_gateway_resource.translate_presigned_url.id
  http_method = aws_api_gateway_method.get_translate_presigned_url.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.generate_translate_presigned_url.arn}/invocations"
}

resource "aws_lambda_permission" "allow_api_gateway_translate_presign" {
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.generate_translate_presigned_url.function_name
  source_arn    = "${aws_api_gateway_rest_api.Food-In-Sight-API.execution_arn}/*/*"
}




# END Translate S3 Signed URL ------------------------------------------------------------------------------------------



# Permissions

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


#Policy for apigateway to invoke upload image lambda
resource "aws_iam_role_policy" "api_gateway_upload_image_lambda_invoke_policy" {
  name   = "api_gateway_upload_image_lambda_invoke_policy"
  role   = aws_iam_role.apigateway_role.id

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

#Allows apigateway to invoke upload image lambda
resource "aws_lambda_permission" "allow_apigateway_invoke_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_image_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

# Deploy API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.upload_image_integration,
    aws_api_gateway_method.upload_image_method,
    aws_api_gateway_method_response.upload_image_response,
    aws_api_gateway_integration_response.upload_image_integration_response,
    aws_api_gateway_integration.upload_integration
  ]

  rest_api_id  = aws_api_gateway_rest_api.Food-In-Sight-API.id
  stage_name = "prod"
}

# Deployment name
# resource "aws_api_gateway_stage" "dev" {
#   rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
#   deployment_id = aws_api_gateway_deployment.deployment.id
#   stage_name = "dev"  # Specifies the stage name
# }

#Testing generated coors policy:

# CORS for /uploadimage (OPTIONS method)
resource "aws_api_gateway_resource" "upload_image_options" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  parent_id   = aws_api_gateway_resource.upload_image.id
  path_part   = "options"
}

resource "aws_api_gateway_method" "upload_image_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id   = aws_api_gateway_resource.upload_image_options.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "upload_image_options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id = aws_api_gateway_resource.upload_image_options.id
  http_method = aws_api_gateway_method.upload_image_options_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "upload_image_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id = aws_api_gateway_resource.upload_image_options.id
  http_method = aws_api_gateway_method.upload_image_options_method.http_method
  status_code = aws_api_gateway_method_response.upload_image_options_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET, POST, PUT, OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration" "upload_image_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id             = aws_api_gateway_resource.upload_image_options.id
  http_method             = aws_api_gateway_method.upload_image_options_method.http_method
  type                    = "MOCK"
  integration_http_method = "NONE"

}

# CORS for /translate (OPTIONS method)
resource "aws_api_gateway_resource" "translate_options" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  parent_id   = aws_api_gateway_resource.file_upload_resource.id
  path_part   = "options"
}

resource "aws_api_gateway_method" "translate_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id   = aws_api_gateway_resource.translate_options.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "translate_options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id = aws_api_gateway_resource.translate_options.id
  http_method = aws_api_gateway_method.translate_options_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "translate_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id = aws_api_gateway_resource.translate_options.id
  http_method = aws_api_gateway_method.translate_options_method.http_method
  status_code = aws_api_gateway_method_response.translate_options_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET, POST, PUT, OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration" "translate_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id             = aws_api_gateway_resource.translate_options.id
  http_method             = aws_api_gateway_method.translate_options_method.http_method
  type                    = "MOCK"
  integration_http_method = "NONE"
}

# CORS for /presign-translate-options (OPTIONS method)
resource "aws_api_gateway_resource" "presign_translate_options" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  parent_id   = aws_api_gateway_rest_api.Food-In-Sight-API.root_resource_id
  path_part   = "presign-translate-options"
}

resource "aws_api_gateway_method" "presign_translate_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id   = aws_api_gateway_resource.presign_translate_options.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "presign_translate_options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id = aws_api_gateway_resource.presign_translate_options.id
  http_method = aws_api_gateway_method.presign_translate_options_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "presign_translate_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id = aws_api_gateway_resource.presign_translate_options.id
  http_method = aws_api_gateway_method.presign_translate_options_method.http_method
  status_code = aws_api_gateway_method_response.presign_translate_options_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET, POST, PUT, OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration" "presign_translate_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.Food-In-Sight-API.id
  resource_id             = aws_api_gateway_resource.presign_translate_options.id
  http_method             = aws_api_gateway_method.presign_translate_options_method.http_method
  type                    = "MOCK"
  integration_http_method = "NONE"
}


output "api_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}/upload"
}
