resource "aws_security_group" "intra_vpc" {
  vpc_id = var.vpc_id
  tags = {
    Name = "intra_vpc_sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "intra_vpc_egress" {
  security_group_id = aws_security_group.intra_vpc.id
  ip_protocol    = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "intra_vpc_ingress" {
  security_group_id = aws_security_group.intra_vpc.id
  ip_protocol    = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}


resource "aws_security_group" "rds" {
  vpc_id = var.vpc_id
  tags = {
    Name = "rds-sg"
  }
}

resource "aws_security_group_rule" "rds_ingress" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = aws_security_group.rds.id
}

