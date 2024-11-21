output "db_instance_id" {
  value = aws_db_instance.rds.id
}

output "endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "arn" {
  value = aws_db_instance.rds.arn
}
