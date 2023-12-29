# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "dev_website_endpoint" {
  value = "http://${aws_s3_bucket_website_configuration.dev.website_endpoint}/index.html"
}

output "environment_table_name" {
  description = "Name of the environment DynamoDB table"
  value       = aws_dynamodb_table.table.name
}

output "environment_table_arn" {
  description = "ARN of the environment DynamoDB table"
  value       = aws_dynamodb_table.table.arn
}
