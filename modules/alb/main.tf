resource "aws_lb" "alb" {
  name               = "main-alb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "instances" {
    name = "instances-tg"
    target_type = "instance"
    port = "80"
    protocol = "HTTP"
    vpc_id = var.vpc_id

}

resource "aws_lb_listener" "aws_lb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instances.arn
  }
}

resource "aws_lb_target_group_attachment" "register_targets" {
  # covert a list of instance objects to a map with instance ID as the key, and an instance
  # object as the value.
  for_each = {
    for k, v in var.aws_instances :
    k => v
  }

  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = each.value.id
  port             = 80
}