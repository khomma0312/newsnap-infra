variable "app_name" {
  type = string
}

variable "db_instance_identifier" {
  description = "停止対象の RDS インスタンス識別子"
  type        = string
}

variable "schedule_expression" {
  description = "EventBridge Scheduler の cron 式（schedule_expression_timezone = Asia/Tokyo で解釈される）"
  type        = string
  default     = "cron(0 0 ? * MON *)" # 毎週月曜 00:00 JST
}
