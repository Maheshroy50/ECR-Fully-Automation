terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "mahesh-strapi-terraform-state"
    key    = "strapi/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.region
}

# --- Use Default VPC Resources ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security Groups (Previously in VPC module) ---

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Security Group (EC2 Instances)
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow traffic from ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 1337 # application port
    to_port         = 1337
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  
  # Allow SSH if needed (optional, removed for security unless requested)

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow PostgreSQL from ECS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Use EXISTING manual ECR repository
data "aws_ecr_repository" "strapi" {
  name = "strapi-fargate-app"
}

module "rds" {
  source          = "./modules/rds"
  project_name    = var.project_name
  private_subnets = data.aws_subnets.default.ids # Using default subnets
  rds_sg_id       = aws_security_group.rds_sg.id
  db_password     = var.db_password
}

module "alb" {
  source         = "./modules/alb"
  project_name   = var.project_name
  vpc_id         = data.aws_vpc.default.id
  public_subnets = data.aws_subnets.default.ids
  alb_sg_id      = aws_security_group.alb_sg.id
}

module "ecs" {
  source           = "./modules/ecs"
  project_name     = var.project_name
  region           = var.region
  ecs_sg_id        = aws_security_group.ecs_sg.id
  public_subnets   = data.aws_subnets.default.ids
  target_group_arn = module.alb.target_group_arn

  # Pass the repository URL and the specific tag we want to deploy
  image_url = data.aws_ecr_repository.strapi.repository_url
  image_tag = var.image_tag
  
  vpc_id = data.aws_vpc.default.id

  db_host     = module.rds.db_host
  db_port     = module.rds.db_port
  db_name     = module.rds.db_name
  db_username = module.rds.db_username
  db_password = var.db_password

  jwt_secret       = var.jwt_secret
  admin_jwt_secret = var.admin_jwt_secret
  app_keys         = var.app_keys
  api_token_salt   = var.api_token_salt
}
