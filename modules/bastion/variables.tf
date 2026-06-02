variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  description = "踏み台を配置するプライベートサブネットID"
  type        = string
}

variable "rds_security_group_id" {
  description = "RDSのセキュリティグループID（踏み台からのingressルールを追加する）"
  type        = string
}

variable "admin_secret_arn" {
  description = "RDS管理者の認証情報が格納されたSecrets ManagerシークレットのARN"
  type        = string
}

variable "app_secret_arn" {
  description = "RDSアプリユーザーの認証情報が格納されたSecrets ManagerシークレットのARN"
  type        = string
}
