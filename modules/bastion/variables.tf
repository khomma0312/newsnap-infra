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
