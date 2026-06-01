variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  description = "RDSに割り当てるセキュリティグループID"
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
