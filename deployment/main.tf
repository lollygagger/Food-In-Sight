#Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

#possibly needed for easy reference of
data "aws_region" "current" {}

locals {
        aws_key = var.aws_key
}