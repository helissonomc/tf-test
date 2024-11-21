output "intra_vpc_sg_id" {
  value = aws_security_group.intra_vpc.id
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}
