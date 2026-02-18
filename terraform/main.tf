

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
# --- Private Network Infrastructure ---

# 1. Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# 2. NAT Gateway (Must be in a PUBLIC subnet)
# We pick the first default subnet for the NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = tolist(data.aws_subnets.default.ids)[0]

  tags = {
    Name = "${var.project_name}-nat-gw"
  }

  depends_on = [aws_eip.nat]
}

# 3. Private Subnets
resource "aws_subnet" "private_1" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.200.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.project_name}-private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.201.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "${var.project_name}-private-subnet-2"
  }
}

# 4. Private Route Table
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# 5. Route Table Associations
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
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
  private_subnets = [aws_subnet.private_1.id, aws_subnet.private_2.id] # NEW: Private Subnets
  rds_sg_id       = aws_security_group.rds_sg.id
  db_password     = var.db_password
}

module "alb" {
  source         = "./modules/alb"
  project_name   = var.project_name
  vpc_id         = data.aws_vpc.default.id
  public_subnets = data.aws_subnets.default.ids # ALB remains in Public Subnets
  alb_sg_id      = aws_security_group.alb_sg.id
}

module "ecs" {
  source           = "./modules/ecs"
  project_name     = var.project_name
  region           = var.region
  ecs_sg_id        = aws_security_group.ecs_sg.id
  public_subnets   = [aws_subnet.private_1.id, aws_subnet.private_2.id] # NEW: ECS in Private Subnets
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
