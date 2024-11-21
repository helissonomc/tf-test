variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
}

variable "instance_type" {
  description = "The instance type for the EC2 instance"
  default     = "t2.micro"
}

variable "public_subnet_id" {
  description = "Subnet ID where the EC2 instance will be launched"
}

variable "security_group_id" {
  description = "Security group ID for the EC2 instance"
}
