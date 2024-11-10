resource "aws_amplify_app" "food-in-sight-deploy" {
  name       = "food-in-sight"
  repository = "https://github.com/SWEN-514-FALL-2024/term-project-2241-swen-514-05-team5"
  access_token = "" #ADD YOUR ACCESS TOKEN HERE

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