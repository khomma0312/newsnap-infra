variable "domain" {
  description = "サービスのドメイン（証明書のドメイン名として使用）"
  type        = string
}

variable "zone_domain" {
  description = "Route53のホストゾーン名（省略時はdomainと同一。サブドメインを使う環境では親ゾーン名を指定）"
  type        = string
  default     = null
}
