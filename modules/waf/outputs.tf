output "web_acl_arn" {
  description = "CloudFront に紐付ける WAF Web ACL の ARN"
  value       = aws_wafv2_web_acl.main.arn
}
