# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Define local variables
locals {
  aws_key = "JC_AWS_KEY" # Remember to replace this with your actual key if needed
}