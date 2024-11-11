provider "aws" {
    region = "us-east-1"
}

locals {
    aws_key = "schwartz514" #CHANGE TO BE YOUR KEY
}

# DynamoDB Table
resource "aws_dynamodb_table" "user_table" {
    name            = "Users"
    billing_mode    = "PROVISIONED"
    read_capacity   = "10"
    write_capacity  = "10"
    hash_key        = "UserName"

    attribute {
        name = "UserName"
        type = "S"
    }
}