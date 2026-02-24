# --- ECS Cluster ---
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# --- Capacity Provider (FARGATE) ---
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# --- Execution Role for Fargate ---
# Hardcoded to bypass iam:GetRole permission error
# ARN: arn:aws:iam::811738710312:role/ecs_fargate_taskRole

resource "aws_ecs_task_definition" "strapi" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024 # 1 vCPU
  memory                   = 2048 # 2 GB
  execution_role_arn       = "arn:aws:iam::811738710312:role/ecs_fargate_taskRole"

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = "${var.image_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "DATABASE_CLIENT", value = "postgres" },
        { name = "DATABASE_HOST", value = var.db_host },
        { name = "DATABASE_PORT", value = tostring(var.db_port) },
        { name = "DATABASE_NAME", value = var.db_name },
        { name = "DATABASE_USERNAME", value = var.db_username },
        { name = "DATABASE_PASSWORD", value = var.db_password },
        { name = "JWT_SECRET", value = var.jwt_secret },
        { name = "ADMIN_JWT_SECRET", value = var.admin_jwt_secret },
        { name = "APP_KEYS", value = var.app_keys },
        { name = "API_TOKEN_SALT", value = var.api_token_salt },
        { name = "DATABASE_SSL", value = "false" }
      ]
    }
  ])
}

# --- ECS Service ---
resource "aws_ecs_service" "strapi" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = var.desired_count

  # Use capacity provider strategy instead of launch_type
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }

  # Use CodeDeploy for Blue/Green
  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_blue_name # Start with Blue
    container_name   = "strapi"
    container_port   = 1337
  }

  # CodeDeploy will manage task definitions and target groups dynamically
  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }
}

# --- CodeDeploy Resources ---
resource "aws_codedeploy_app" "strapi" {
  compute_platform = "ECS"
  name             = "${var.project_name}-codedeploy-app"
}

resource "aws_codedeploy_deployment_group" "strapi" {
  app_name               = aws_codedeploy_app.strapi.name
  deployment_group_name  = "${var.project_name}-codedeploy-group"
  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"
  service_role_arn       = "arn:aws:iam::811738710312:role/codedeploy_role"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.strapi.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.listener_prod_arn]
      }
      
      test_traffic_route {
        listener_arns = [var.listener_test_arn]
      }

      target_group {
        name = var.target_group_blue_name
      }

      target_group {
        name = var.target_group_green_name
      }
    }
  }
}
