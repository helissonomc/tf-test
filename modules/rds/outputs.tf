output "postgres_endpoint" {
    value = aws_db_instance.rds.endpoint
}