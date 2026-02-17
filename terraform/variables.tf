variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "strapi-app"
}

variable "instance_type" {
  description = "EC2 Instance Type for ECS"
  type        = string
  default     = "t2.micro"
}

variable "image_tag" {
  description = "Docker image tag to deploy (e.g., git sha)"
  type        = string
  default     = "latest"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Strapi JWT Secret"
  type        = string
  sensitive   = true
}

variable "admin_jwt_secret" {
  description = "Strapi Admin JWT Secret"
  type        = string
  sensitive   = true
}

variable "app_keys" {
  description = "Strapi App Keys"
  type        = string
  sensitive   = true
}

variable "api_token_salt" {
  description = "Strapi API Token Salt"
  type        = string
  sensitive   = true
}
