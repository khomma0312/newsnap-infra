resource "aws_cognito_user_pool" "main" {
  name = "${var.app_name}-user-pool"

  username_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  auto_verified_attributes = ["email"]

  # ユーザー登録時の招待メッセージの内容。
  verification_message_template {
    # 検証にはトークンではなく、リンクを使用する。
    default_email_option  = "CONFIRM_WITH_LINK"
    email_message         = " 検証コードは {####} です。"
    email_message_by_link = " E メールアドレスを検証するには、次のリンクをクリックしてください。{##Verify Email##} "
    email_subject         = " 検証コード"
    email_subject_by_link = " 検証リンク"
    sms_message           = " 検証コードは {####} です。"
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.app_name # マネージドドメインを使う
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.app_name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers         = ["COGNITO"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  generate_secret     = true
  explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

resource "aws_secretsmanager_secret" "cognito_client_secret" {
  name                    = "/${var.app_name}/cognito/client_secret"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "cognito_client_secret" {
  secret_id     = aws_secretsmanager_secret.cognito_client_secret.id
  secret_string = aws_cognito_user_pool_client.main.client_secret
}

resource "aws_ssm_parameter" "cognito_user_pool_id" {
  name  = "/${var.app_name}/cognito/user_pool_id"
  type  = "String"
  value = aws_cognito_user_pool.main.id
}

resource "aws_ssm_parameter" "cognito_client_id" {
  name  = "/${var.app_name}/cognito/client_id"
  type  = "String"
  value = aws_cognito_user_pool_client.main.id
}

resource "aws_ssm_parameter" "cognito_domain" {
  name  = "/${var.app_name}/cognito/domain"
  type  = "String"
  value = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

resource "aws_ssm_parameter" "cognito_redirect_uri" {
  name  = "/${var.app_name}/cognito/redirect_uri"
  type  = "String"
  value = var.callback_urls[0]
}

resource "aws_ssm_parameter" "frontend_url" {
  name  = "/${var.app_name}/app/frontend_url"
  type  = "String"
  value = var.logout_urls[0]
}
