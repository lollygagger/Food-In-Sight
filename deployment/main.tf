#Configure the AWS provider
provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

#possibly needed for easy reference of region
data "aws_region" "current" {}

locals {
        aws_key = var.aws_key
}