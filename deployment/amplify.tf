# Reference the existing Cognito User Pool using a data source
data "aws_cognito_user_pool" "existing_user_pool" {
  user_pool_id = "us-east-1_ThHadgoKx"  # Use the ID from aws-exports.js
}

# Reference the existing Cognito User Pool Client using a data source
data "aws_cognito_user_pool_client" "existing_user_pool_client" {
  user_pool_id = data.aws_cognito_user_pool.existing_user_pool.id
  client_id    = "26h3p878ul4me04toa7t0k1mk"  # Use the client ID from aws-exports.js
}

# Existing Amplify app creation using the shared Cognito user pool
resource "aws_amplify_app" "food-in-sight-deploy" {
  name       = "food-in-sight"
  repository = "https://github.com/SWEN-514-FALL-2024/term-project-2241-swen-514-05-team5"
  access_token = var.github_token

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

# Outputs for user pool and client references
output "user_pool_id" {
  value = data.aws_cognito_user_pool.existing_user_pool.id
}

output "user_pool_client_id" {
  value = data.aws_cognito_user_pool_client.existing_user_pool_client.id
}
