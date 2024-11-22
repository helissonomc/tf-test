variable "security_group_id" {
  description = "Security group ID for the ALB instance"
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB instance"
}

variable "vpc_id" {}

variable "aws_instances" {}