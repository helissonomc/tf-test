resource "aws_ecs_cluster" "main" {
  name = "longrent-prod-tf"
}

data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# --- ECS Node Role ---
data "aws_iam_policy_document" "ecs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_node_role" {
  name_prefix        = "demo-ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = "demo-ecs-node-profile"
  path        = "/ecs/instance/"
  role        = aws_iam_role.ecs_node_role.name
}

resource "aws_launch_template" "ecs_ec2" {
  name_prefix            = "demo-ecs-ec2-"
  image_id               = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type          = "t2.micro"
  vpc_security_group_ids = [var.aws_security_group_id]

  key_name = "demo-ecs-key"
  iam_instance_profile { arn = aws_iam_instance_profile.ecs_node.arn }
  monitoring { enabled = true }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config;
    EOF
  )
}

# --- ECS ASG ---

resource "aws_autoscaling_group" "ecs" {
  name_prefix               = "demo-ecs-asg-"
  vpc_zone_identifier       = var.public_subnet_ids
  min_size                  = 1
  max_size                  = 2
  desired_capacity = 1
  health_check_grace_period = 0
  health_check_type         = "EC2"
  protect_from_scale_in     = false

  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "demo-ecs-cluster"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}


# --- ECS Capacity Provider ---

resource "aws_ecs_capacity_provider" "main" {
  name = "demo-ecs-ec2-new"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    base              = 1
    weight            = 100
  }
}


# --- ECS Task Role ---

data "aws_iam_policy_document" "ecs_task_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name_prefix        = "demo-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role" "ecs_exec_role" {
  name_prefix        = "demo-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- Cloud Watch Logs ---

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/demo"
  retention_in_days = 1
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "app" {
  family             = "demo-prod-td"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  network_mode       = "awsvpc"
  cpu                = 900
  memory             = 900
  requires_compatibilities = ["EC2"]

  container_definitions = jsonencode([{
    name         = "webserver-test"
    image        = "448049820193.dkr.ecr.us-east-1.amazonaws.com/app-ecr:latest"
    cpu          = 0
    essential    = true
    entryPoint   = ["/bin/sh", "-c", "python manage.py migrate && python manage.py runserver 0.0.0.0:80"]

    portMappings = [{
      name            = "webserver-test-80-tcp"
      containerPort   = 80
      hostPort        = 80
      protocol        = "tcp"
      appProtocol     = "http"
    }]

    environment = [
      { name = "POSTGRES_USER", value = "postgis" },
      { name = "POSTGRES_HOST", value = split(":", var.postgres_endpoint)[0] },
      { name = "CSRF_TRUSTED_ORIGINS", value = "http://localhost,https://localhost" },
      { name = "SECRET_KEY", value = "*nq!0brcs4&v9vjqmvxd05_0)tv_-#ip&g!bh-=*9)vf*l!4*v_test" },
      { name = "POSTGRES_PASSWORD", value = var.password },
      { name = "POSTGRES_PORT", value = "5432" },
      { name = "POSTGRES_DB", value = var.db_name },
      { name = "DEBUG", value = "1" },
      { name = "POSTGRES_USER", value = var.username}
    ]

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = "us-east-1",
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
        "awslogs-stream-prefix" = "app"
      }
    },
  }])

  runtime_platform {
    cpu_architecture       = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_task_definition" "newservice" {
  family             = "prod-td"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  network_mode       = "awsvpc"
  cpu                = 900
  memory             = 900
  requires_compatibilities = ["EC2"]

  container_definitions = jsonencode([{
    name         = "newservice-test"
    image        = "httpd"
    cpu          = 0
    essential    = true

    portMappings = [{
      name            = "newservice-test-80-tcp"
      containerPort   = 80
      hostPort        = 80
      protocol        = "tcp"
      appProtocol     = "http"
    }]

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = "us-east-1",
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
        "awslogs-stream-prefix" = "newservice"
      }
    },
  }])

  runtime_platform {
    cpu_architecture       = "X86_64"
    operating_system_family = "LINUX"
  }
}

# --- ECS Service ---

resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

  network_configuration {
    security_groups = [var.aws_security_group_id]
    subnets         = var.public_subnet_ids
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    base              = 1
    weight            = 100
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_lb_target_group.app]

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "webserver-test"
    container_port   = 80
  }
}

resource "aws_ecs_service" "newservice" {
  name            = "newservice"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.newservice.arn
  desired_count   = 1

  network_configuration {
    security_groups = [var.aws_security_group_id]
    subnets         = var.public_subnet_ids
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    base              = 1
    weight            = 100
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_lb_target_group.newservice]

  load_balancer {
    target_group_arn = aws_lb_target_group.newservice.arn
    container_name   = "newservice-test"
    container_port   = 80
  }
}

# --- ALB ---

resource "aws_lb" "main" {
  name               = "demo-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.aws_security_group_id]
}

resource "aws_lb_target_group" "app" {
  name_prefix = "app-"
  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  port        = 80
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/api/schema/swagger-ui/"
    port                = 80
    matcher             = 200
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "newservice" {
  name_prefix = "ns-"
  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  port        = 80
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = 80
    matcher             = 200
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.id
  }
}

resource "aws_lb_listener_rule" "newservice" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10  # Ensure the priority is unique and appropriate

  condition {
    path_pattern {
      values = ["/newservice/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.newservice.arn
  }

  tags = {
    Name = "newservice-name"
  }
}
