# AWS Region
variable "region" {
  default = "us-east-1"  # or your preferred region
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
        aws_key = "AWS_KEY" #CHANGE TO BE YOUR KEY
}