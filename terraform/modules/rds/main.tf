resource "aws_db_subnet_group" "default" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "14.10"
  instance_class         = "db.t3.micro"
  identifier             = "${var.project_name}-db"
  db_name                = "strapi"
  username               = "strapi"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [var.rds_sg_id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false

  tags = {
    Name = "${var.project_name}-db"
  }
}
