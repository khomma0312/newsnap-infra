output "cluster_name" { value = aws_ecs_cluster.migration.name }
output "task_definition_arn" { value = aws_ecs_task_definition.migration.arn }
output "ecr_repository_url" { value = aws_ecr_repository.migration.repository_url }
output "security_group_id" { value = aws_security_group.migration.id }
