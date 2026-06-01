terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_wafv2_web_acl" "main" {
  name  = "${var.app_name}-web-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # 1. 既知の悪意ある IP を最初に弾く（WCU: 25）
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  # 2. SQLi・XSS 等の一般的な Web 攻撃（WCU: 700）
  # Count モードで誤検知を確認後、none に切り替える
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 20

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # 3. Log4Shell 等の既知の危険な入力（WCU: 200）
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.app_name}-web-acl"
    sampled_requests_enabled   = true
  }
}
