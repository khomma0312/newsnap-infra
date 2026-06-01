output "repository_url" {
  description = "ECR リポジトリ URL（CI/CD でのイメージ push 先）"
  value       = aws_ecr_repository.backend.repository_url
}
