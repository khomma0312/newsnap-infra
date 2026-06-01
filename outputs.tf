output "cloudfront_domain" {
  description = "フロントエンドの CloudFront ドメイン"
  value       = module.cloudfront.cloudfront_domain
}

output "alb_dns" {
  description = "バックエンド ALB の DNS 名"
  value       = module.alb.alb_dns
}

output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "cognito_client_id" {
  value = module.cognito.client_id
}

output "ecr_repository_url" {
  description = "ECR リポジトリ URL（CI/CD でのイメージ push 先）"
  value       = module.ecr.repository_url
}
