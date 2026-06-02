variable "app_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "rds_security_group_id" {
  description = "RDSのセキュリティグループID（マイグレーション用ingressルールを追加する）"
  type        = string
}

variable "db_host_param_arn" {
  description = "DBホストを格納したSSMパラメータのARN"
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
