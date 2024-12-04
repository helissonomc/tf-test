resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group-new"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "db-subnet-group-new"
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage      = var.allocated_storage
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = var.db_name
  username               = var.username
  password               = var.password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.id
  publicly_accessible    = false
  vpc_security_group_ids = [var.vpc_security_group_id]
  skip_final_snapshot    = var.skip_final_snapshot

  tags = {
    Name = "rds-instance"
  }
}
