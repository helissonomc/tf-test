output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.subnets.public_subnets
}

output "private_subnets" {
  value = module.subnets.private_subnets
}

output "nat_gateway_id" {
  value = module.nat_gateway.nat_gateway_id
}

output "ec2_instance_id" {
  value = module.ec2.instance_id
}

output "rds_instance_endpoint" {
  value = module.rds.endpoint
}
