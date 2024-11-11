
# API Gateway and Integration
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "my-api"
  description = "My API Gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
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
    aws_api_gateway_integration.upload_image_integration,
    aws_api_gateway_method.upload_image_method,
    aws_api_gateway_method_response.upload_image_response,
    aws_api_gateway_integration_response.upload_image_integration_response
  ]

  rest_api_id = aws_api_gateway_rest_api.my_api.id
}

# Deployment name
resource "aws_api_gateway_stage" "dev" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name = "dev"  # Specifies the stage name
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