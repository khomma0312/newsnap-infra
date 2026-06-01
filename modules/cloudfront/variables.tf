variable "app_name" {
  type = string
}

variable "domains" {
  description = "CloudFrontのエイリアスおよびRoute53 Aレコードとするドメインのリスト"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "CloudFront用ACM証明書のARN（us-east-1）"
  type        = string
}

variable "zone_id" {
  description = "Route53ホストゾーンID"
  type        = string
}

variable "s3_bucket_id" {
  description = "フロントエンドS3バケットID"
  type        = string
}

variable "s3_bucket_arn" {
  description = "フロントエンドS3バケットARN（バケットポリシー用）"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "フロントエンドS3バケットのリージョナルドメイン名"
  type        = string
}

variable "alb_dns_name" {
  description = "バックエンドALBのDNS名"
  type        = string
}

variable "cloudfront_secret" {
  description = "CloudFront→ALB間の認証ヘッダー値"
  type        = string
  sensitive   = true
}

variable "web_acl_arn" {
  description = "CloudFront に紐付ける WAF Web ACL の ARN（us-east-1）"
  type        = string
}
