variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "acm_certificate_arn" {
  description = "ALB HTTPSリスナー用ACM証明書のARN（ap-northeast-1）"
  type        = string
}

variable "zone_id" {
  description = "Route53ホストゾーンID"
  type        = string
}

variable "api_domain" {
  description = "ALBに割り当てるカスタムドメイン（例: api.kh-webdev-nibble.net）"
  type        = string
}

variable "security_group_id" {
  description = "ALBに割り当てるセキュリティグループID"
  type        = string
}
