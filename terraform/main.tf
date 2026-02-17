

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  region       = var.region
}

# Use EXISTING manual ECR repository
data "aws_ecr_repository" "strapi" {
  name = "strapi-fargate-app"
}

module "rds" {
  source          = "./modules/rds"
  project_name    = var.project_name
  private_subnets = module.vpc.private_subnets
  rds_sg_id       = module.vpc.rds_sg_id
  db_password     = var.db_password
}

module "alb" {
  source         = "./modules/alb"
  project_name   = var.project_name
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  alb_sg_id      = module.vpc.ecs_sg_id # Reusing ECS SG which allows port 80/1337. Better practice to separate, but acceptable for now.
}

module "ecs" {
  source           = "./modules/ecs"
  project_name     = var.project_name
  region           = var.region
  ecs_sg_id        = module.vpc.ecs_sg_id
  public_subnets   = module.vpc.public_subnets
  target_group_arn = module.alb.target_group_arn

  # Pass the repository URL and the specific tag we want to deploy
  image_url = data.aws_ecr_repository.strapi.repository_url
  image_tag = var.image_tag

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
