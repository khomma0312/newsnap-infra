variable "app_name" {
  type = string
}

variable "app_port" {
  description = "アプリケーションのコンテナポート（ECS SG の ingress ルール用）"
  type        = number
  default     = 3001
}
