output "cloudfront_cert_arn" {
  description = "CloudFront用ACM証明書のARN（us-east-1、DNS検証済み）"
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}

output "zone_id" {
  description = "Route53ホストゾーンID"
  value       = data.aws_route53_zone.main.zone_id
}

output "alb_cert_arn" {
  description = "ALB用ACM証明書のARN（ap-northeast-1、DNS検証済み）"
  value       = aws_acm_certificate_validation.alb.certificate_arn
}
