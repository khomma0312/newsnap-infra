variable "app_name" {
  type = string
}

variable "instance_id" {
  description = "Bastion EC2のインスタンスID"
  type        = string
}

variable "admin_secret_id" {
  description = "RDS管理者の認証情報が格納されたSecrets ManagerのシークレットID"
  type        = string
}

variable "rds_endpoint" {
  description = "RDSのエンドポイント"
  type        = string
}

variable "db_name" {
  description = "RDSのデータベース名"
  type        = string
}

variable "app_secret_id" {
  description = "RDSアプリユーザーの認証情報が格納されたSecrets ManagerのシークレットID"
  type        = string
}
