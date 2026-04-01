output "table_name" {
  description = "DynamoDB table name"
  value       = module.database.table_name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = module.database.table_arn
}

output "table_id" {
  description = "DynamoDB table ID"
  value       = module.database.table_id
}
