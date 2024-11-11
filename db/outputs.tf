output "lambda_function_arn" {
    value = aws_lambda_function.lambda_function.arn
}

output "api_gateway_url" {
    value = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/prod"
}

output "dynamodb_table_name" {
    value = aws_dynamodb_table.user_table.name
}
