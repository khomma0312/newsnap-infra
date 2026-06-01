output "db_endpoint" { value = aws_db_instance.main.address }
output "db_instance_identifier" { value = aws_db_instance.main.identifier }
output "db_admin_credentials_secret_arn" { value = aws_secretsmanager_secret.db_admin_credentials.arn }
output "db_name_param_arn" { value = aws_ssm_parameter.db_name.arn }
output "db_host_param_arn" { value = aws_ssm_parameter.db_host.arn }
output "db_app_credentials_secret_arn" { value = aws_secretsmanager_secret.db_app_credentials.arn }
