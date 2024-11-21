variable "private_subnet_ids" {
  description = "List of private subnet IDs for the RDS instance"
}

variable "vpc_security_group_id" {
  description = "Security group ID for the RDS instance"
}

variable "allocated_storage" {
  description = "The size of the RDS storage in GB"
  default     = 20
}

variable "engine" {
  description = "The database engine to use"
  default     = "postgres"
}

variable "engine_version" {
  description = "The version of the database engine"
  default     = "16.3"
}

variable "instance_class" {
  description = "The instance class for the RDS instance"
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "The name of the database"
}

variable "username" {
  description = "The username for the RDS instance"
}

variable "password" {
  description = "The password for the RDS instance"
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on RDS instance deletion"
  default     = true
}
