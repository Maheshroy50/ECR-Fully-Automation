variable "project_name" {
  description = "Project name"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security Group ID for RDS"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
