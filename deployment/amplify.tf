resource "aws_amplify_app" "food-in-sight-deploy" {
  name       = "food-in-sight"

  # GitHub Repository and Access Token for the Amplify App
  repository = "https://github.com/SWEN-514-FALL-2024/term-project-2241-swen-514-05-team5"
  access_token = var.github_token

  # The default build_spec added by the Amplify Console for React.
  build_spec = <<-EOT
    version: 0.1
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

resource "aws_cognito_user_pool" "user_pool" {
  name = "food-in-sight-user-pool"
  id   = "us-east-1_ThHadgoKx"  # Match the value in the aws-exports.js file

  # Allow users to log in with their email
  alias_attributes = ["email"]
  auto_verified_attributes = ["email"]  # Automatically verify email

  # Password policy (match aws-exports.js settings)
  password_policy {
    minimum_length = 8
    require_uppercase = false
    require_numbers = false
    require_symbols = false
  }

  # MFA Configuration (as per aws-exports.js)
  mfa_configuration = "OFF"
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "food-in-sight-user-pool-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  generate_secret = false

  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_CUSTOM_AUTH"]
  id_token_validity   = 3600
  access_token_validity = 3600
}

resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "food-in-sight-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    provider_name = "cognito-idp.us-east-1.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
    client_id     = aws_cognito_user_pool_client.user_pool_client.id
  }
}

resource "aws_iam_role" "authenticated_role" {
  name = "food-in-sight-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRoleWithWebIdentity"
        Effect    = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity_pool.id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "authenticated_policy" {
  name = "food-in-sight-authenticated-policy"
  role = aws_iam_role.authenticated_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:GetFederationToken"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

output "identity_pool_id" {
  value = aws_cognito_identity_pool.identity_pool.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}

output "user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

