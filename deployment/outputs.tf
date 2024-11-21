# # Outputs
# output "api_endpoint" {
#     description = "The API endpoint for the User Processing API"
#     value       = "${aws_api_gateway_deployment.api_deployment.invoke_url}"
# }

# output "dynamodb_table_name" {
#     description = "The DynamoDB table name"
#     value       = aws_dynamodb_table.user_table.name
# }