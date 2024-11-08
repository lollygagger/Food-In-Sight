#Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

locals {
        aws_key = "JC_AWS_KEY" #CHANGE TO BE YOUR KEY
}