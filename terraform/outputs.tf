output "ecr_repository_url" {
  value = data.aws_ecr_repository.strapi.repository_url
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "rds_endpoint" {
  value = module.rds.db_host
}
