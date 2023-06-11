output "alb_target_group_arn" {
  description = "Alb target group arn"
  value       = aws_alb_target_group.default.arn
}

output "load_balancer_arn" {
  value = aws_lb.default.arn
}

output "target_group_arn" {
  value = aws_alb_target_group.default.arn
}

output "listener_http_arn" {
  value = aws_alb_listener.http.arn
}

output "lb_dns_name" {
  value = aws_lb.default.dns_name
}

output "lb_endpoint" {
  value = "http://${aws_lb.default.dns_name}"
}


