resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# --- Blue Target Group ---
resource "aws_lb_target_group" "blue" {
  name        = "${var.project_name}-tg-blue"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-tg-blue"
  }
}

# --- Green Target Group ---
resource "aws_lb_target_group" "green" {
  name        = "${var.project_name}-tg-green"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-tg-green"
  }
}

# --- Production Listener (Port 80) ---
# CodeDeploy will shift traffic from Blue to Green on this listener
resource "aws_lb_listener" "prod" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [default_action] # CodeDeploy manages this
  }
}

# --- Test Listener (Port 8080) ---
# Used by CodeDeploy to verify the Green deployment before shifting production traffic
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.main.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  lifecycle {
    ignore_changes = [default_action] # CodeDeploy manages this
  }
}
