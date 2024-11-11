resource "aws_amplify_app" "food-in-sight-deploy" {
  name       = "food-in-sight"

  # We might want to switch over to an s3 bucket for easier permissions management
  # This current method is good because it always gets the most up to date commits on main but
  # requiring users to setup a github access token could be annoying
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