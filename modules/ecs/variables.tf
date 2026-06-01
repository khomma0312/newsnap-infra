variable "app_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "alb_target_group" {
  type = string
}

variable "db_host_param_arn" {
  description = "DBホストを格納したSSMパラメータのARN"
  type        = string
}

variable "cognito_user_pool_id_param_arn" {
  description = "Cognito ユーザープールIDを格納したSSMパラメータのARN"
  type        = string
}

variable "cognito_client_id_param_arn" {
  description = "Cognito クライアントIDを格納したSSMパラメータのARN"
  type        = string
}

variable "cognito_domain_param_arn" {
  description = "Cognito ドメインを格納したSSMパラメータのARN"
  type        = string
}

variable "cognito_redirect_uri_param_arn" {
  description = "Cognito リダイレクトURIを格納したSSMパラメータのARN"
  type        = string
}

variable "frontend_url_param_arn" {
  description = "フロントエンドURLを格納したSSMパラメータのARN"
  type        = string
}

variable "db_name_param_arn" {
  description = "DB名を格納したSSMパラメータのARN"
  type        = string
}

variable "db_app_credentials_secret_arn" {
  description = "アプリ用DBユーザーの認証情報を格納したSecrets ManagerシークレットのARN"
  type        = string
}

variable "cognito_client_secret_arn" {
  description = "Cognito クライアントシークレットを格納したSecrets ManagerシークレットのARN"
  type        = string
}

variable "security_group_id" {
  description = "ECSタスクに割り当てるセキュリティグループID"
  type        = string
}
