# # Reference the existing Cognito User Pool using a data source
# data "aws_cognito_user_pool" "existing_user_pool" {
#   user_pool_id = "us-east-1_ThHadgoKx"  # Use the ID from aws-exports.js
# }
#
# # Reference the existing Cognito User Pool Client using a data source
# data "aws_cognito_user_pool_client" "existing_user_pool_client" {
#   user_pool_id = data.aws_cognito_user_pool.existing_user_pool.id
#   client_id    = "26h3p878ul4me04toa7t0k1mk"  # Use the client ID from aws-exports.js
# }

resource "aws_cognito_user_pool" "food-in-sight-user-pool" {
  name = "food-in-sight-user-pool"
}

resource "aws_cognito_user_pool_client" "food-in-sight-user-pool-client" {
  name            = "food-in-sight-client"
  user_pool_id    = aws_cognito_user_pool.food-in-sight-user-pool.id
  generate_secret = false
}

resource "aws_cognito_identity_pool" "food-in-sight-identity-pool" {
  identity_pool_name               = "food-in-sight-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id     = aws_cognito_user_pool_client.food-in-sight-user-pool-client.id
    provider_name = aws_cognito_user_pool.food-in-sight-user-pool.endpoint
  }
}


# Create the amplify app with environment variables for the APIs and cognito
resource "aws_amplify_app" "food-in-sight-deploy" {
  name         = "food-in-sight"
  repository   = "https://github.com/SWEN-514-FALL-2024/term-project-2241-swen-514-05-team5"
  access_token = var.github_token

  environment_variables = {
    VITE_USER_DIET_API_GATEWAY_URL  = aws_api_gateway_deployment.deployment.invoke_url
    VITE_API_GATEWAY_URL            = aws_api_gateway_deployment.api_deployment.invoke_url
    VITE_COGNITO_USERPOOL_ID        = aws_cognito_user_pool.food-in-sight-user-pool.id
    VITE_COGNITO_USERPOOL_CLIENT_ID = aws_cognito_user_pool_client.food-in-sight-user-pool-client.id
    VITE_COGNITO_IDENTITY_POOL_ID   = aws_cognito_identity_pool.food-in-sight-identity-pool.id
  }

  depends_on    = [
    aws_api_gateway_deployment.deployment,
    aws_api_gateway_deployment.api_deployment,
    aws_cognito_user_pool.food-in-sight-user-pool,
    aws_cognito_user_pool_client.food-in-sight-user-pool-client,
    aws_cognito_identity_pool.food-in-sight-identity-pool
  ]

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - cd food-in-sight
            - npm install
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: food-in-sight/dist
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT
}

output "amplify_app_url" {
  value = aws_amplify_app.food-in-sight-deploy.id
}
