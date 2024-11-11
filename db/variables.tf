variable "aws_region" {
    default = "us-east-1"
}

variable "lambda_name" {
    default = "user-process"
}

variable "dynamodb_table_name" {
    default = "Users"
}

variable "api_gateway_name" {
    default = "MyApiGateway"
}

variable "default_data" {
    type = list(map(string))
    default = jsondecode(file("default_data.json"))
}
