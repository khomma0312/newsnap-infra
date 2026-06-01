output "user_pool_id" { value = aws_cognito_user_pool.main.id }
output "client_id" { value = aws_cognito_user_pool_client.main.id }
output "domain" { value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com" }

output "client_secret_arn" { value = aws_secretsmanager_secret.cognito_client_secret.arn }

output "user_pool_id_param_arn" { value = aws_ssm_parameter.cognito_user_pool_id.arn }
output "client_id_param_arn" { value = aws_ssm_parameter.cognito_client_id.arn }
output "domain_param_arn" { value = aws_ssm_parameter.cognito_domain.arn }
output "redirect_uri_param_arn" { value = aws_ssm_parameter.cognito_redirect_uri.arn }
output "frontend_url_param_arn" { value = aws_ssm_parameter.frontend_url.arn }

data "aws_region" "current" {}
