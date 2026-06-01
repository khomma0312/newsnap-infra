output "security_group_id" {
  description = "ECS タスクのセキュリティグループID（RDS の ingress ルール参照用）"
  value       = var.security_group_id
}
