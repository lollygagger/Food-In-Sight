variable "aws_key" {
  type = string
  default = "my-key"
  description = "This is your AWS key"
}

variable "github_token"{
  type = string
  description = "This is your Github Access Token that amplify uses to pull the repo"
}

variable "region" {
  type = string
  description = "This is the AWS region you wish to start these resources in"
}