# AWS Region
variable "region" {
  default = "us-east-1"  # or your preferred region
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
        aws_key = "PC_US_EAST_1" #CHANGE TO BE YOUR KEY
}