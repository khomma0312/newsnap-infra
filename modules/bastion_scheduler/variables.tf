variable "app_name" {
  type = string
}

variable "bastion_instance_id" {
  description = "停止対象の踏み台 EC2 インスタンス ID"
  type        = string
}

variable "schedule_expression" {
  description = "EventBridge Scheduler の cron 式（schedule_expression_timezone = Asia/Tokyo で解釈される）"
  type        = string
  default     = "cron(0 23 * * ? *)" # 毎日 23:00 JST
}
