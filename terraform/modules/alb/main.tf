resource "aws_security_group" "default" {
  count = var.security_group_id == "" ? 1 : 0
  name        = format("%s-%s-%s-alb", var.component, var.env, var.application)
  description = "Allow ALB inbound traffic"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value["description"]
      cidr_blocks = [var.current_ip_address_cidr]
      from_port   = ingress.value["from_port"]
      protocol    = "tcp"
      to_port     = ingress.value["to_port"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_lb" "default" {
  name                       = format("%s-%s-%s-alb", var.component, var.env, var.application)
  security_groups            = var.security_group_id != "" ? [var.security_group_id] : [aws_security_group.default[0].id]
  load_balancer_type         = "application"
  subnets                    = var.subnet_ids
  internal                   = false
  enable_deletion_protection = false
  preserve_host_header       = true
  enable_http2               = true
  tags                       = var.tags
}

resource "aws_alb_target_group" "default" {
  name        = format("%s-%s-%s-tg", var.component, var.env, var.application)
  port        = var.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  tags        = var.tags
  deregistration_delay = 5
  load_balancing_cross_zone_enabled = true
}


resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.default.id
  port              = var.port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.default.id
    type             = "forward"
  }
  tags = var.tags

}

##intentional non standard redirrect
#resource "aws_alb_listener" "https" {
#  load_balancer_arn = aws_lb.default.id
#  port              = 443
#  protocol          = "HTTPS"
#
#  default_action {
#    type = "redirect"
#
#    redirect {
#      port        = var.port
#      protocol    = "HTTP"
#      status_code = "HTTP_302"
#    }
#  }
#  tags = var.tags
#}
