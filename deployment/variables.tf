variable "aws_key" {
  type = string
  default = "my-key"
  description = "This is your AWS key"
}

variable "region" {
  type = string
  description = "This is the AWS region you wish to start these resources in"
}