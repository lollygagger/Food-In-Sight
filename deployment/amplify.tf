resource "aws_cognito_user_pool" "food-in-sight-user-pool" {
  name = "food-in-sight-user-pool"

  alias_attributes = ["email"]
  auto_verified_attributes = ["email"]

  schema {
    name     = "email"
    required = true
    attribute_data_type = "String"

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }
}

resource "aws_cognito_user_pool_client" "food-in-sight-user-pool-client" {
  name            = "food-in-sight-client"
  user_pool_id    = aws_cognito_user_pool.food-in-sight-user-pool.id
  generate_secret = false

  # allowed_oauth_flows_user_pool_client = true
  # allowed_oauth_flows                  = ["code", "implicit"]
  # allowed_oauth_scopes                 = ["email", "openid", "profile"]

  # Callback URLs for redirection
  # callback_urls = ["https://your-app-url.com/callback"]
  # logout_urls   = ["https://your-app-url.com/logout"]
}

resource "aws_cognito_identity_pool" "food-in-sight-identity-pool" {
  identity_pool_name               = "food-in-sight-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id     = aws_cognito_user_pool_client.food-in-sight-user-pool-client.id
    provider_name = "cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.food-in-sight-user-pool.id}"
  }
}

resource "aws_amplify_branch" "main" {
  app_id            = "d1c2naelj7l2nf" # Manually setting the app_id to match the existing deployed amplify app
  branch_name       = "main"
  enable_auto_build = true

  lifecycle {
    prevent_destroy = true
  }

  environment_variables = {
    VITE_USER_DIET_API_GATEWAY_URL  = aws_api_gateway_deployment.deployment.invoke_url
    VITE_API_GATEWAY_URL            = aws_api_gateway_deployment.api_deployment.invoke_url
    VITE_COGNITO_USERPOOL_ID        = aws_cognito_user_pool.food-in-sight-user-pool.id
    VITE_COGNITO_USERPOOL_CLIENT_ID = aws_cognito_user_pool_client.food-in-sight-user-pool-client.id
    VITE_COGNITO_IDENTITY_POOL_ID   = aws_cognito_identity_pool.food-in-sight-identity-pool.id
  }

  depends_on = [
    aws_cognito_user_pool.food-in-sight-user-pool,
    aws_cognito_user_pool_client.food-in-sight-user-pool-client,
    aws_cognito_identity_pool.food-in-sight-identity-pool
  ]
}

output "amplify_branch_url" {
  value = "https://${aws_amplify_branch.main.branch_name}.${aws_amplify_branch.main.app_id}.amplifyapp.com/"
}

output "userpool_client_id" {
  value = aws_cognito_user_pool_client.food-in-sight-user-pool-client.id
}

output "userpool_client_arn" {
  value = aws_cognito_user_pool_client.food-in-sight-user-pool-client.user_pool_id
}
