output "alb_dns" {
  value = aws_lb.main.dns_name
}

output "api_domain" {
  description = "ALBのカスタムドメイン（CloudFrontのオリジンとして使用）"
  value       = var.api_domain
}

output "target_group_arn" {
  value = aws_lb_target_group.backend.arn
}

output "cloudfront_secret" {
  value     = random_password.cloudfront_secret.result
  sensitive = true
}

output "security_group_id" {
  description = "ALBのセキュリティグループID"
  value       = var.security_group_id
}
