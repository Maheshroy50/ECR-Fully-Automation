variable "project_name" {
  description = "Project name"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "ecs_sg_id" {
  description = "Security Group ID for ECS"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "target_group_blue_name" {
  description = "ALB Blue Target Group Name"
  type        = string
}

variable "target_group_green_name" {
  description = "ALB Green Target Group Name"
  type        = string
}

variable "listener_prod_arn" {
  description = "ALB Production Listener ARN"
  type        = string
}

variable "listener_test_arn" {
  description = "ALB Test Listener ARN"
  type        = string
}

variable "image_url" {
  description = "Docker image URL (Repository URL)"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
}

variable "cpu" {
  description = "Fargate CPU"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate Memory"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}



variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

# Database Variables
variable "db_host" {
  type = string
}

variable "db_port" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

# Strapi Secrets
variable "jwt_secret" {
  type      = string
  sensitive = true
}

variable "admin_jwt_secret" {
  type      = string
  sensitive = true
}

variable "app_keys" {
  type      = string
  sensitive = true
}

variable "api_token_salt" {
  type      = string
  sensitive = true
}
