#Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

locals {
        aws_key = "mainusa1" #CHANGE TO BE YOUR KEY
}