variable "backend_bucket_name" {
  description = "Terraformの状態ファイルを保存するS3バケット名"
  type        = string
}

variable "app_name" {
  description = "アプリケーション名"
  type        = string
}

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
}

variable "zone_domain" {
  description = "Route53ホストゾーン名（dev/prod共有）"
  type        = string
}

variable "db_name" {
  description = "RDS データベース名"
  type        = string
}

variable "db_admin_user" {
  description = "RDS マスターユーザー名"
  type        = string
}
