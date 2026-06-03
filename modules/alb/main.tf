resource "aws_lb" "main" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [var.security_group_id]
}

resource "aws_lb_target_group" "backend" {
  name        = "${var.app_name}-tg"
  port        = 3001
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path = "/health"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  # デフォルトは400。X-Custom-Headerが一致するリクエスト（=CloudFront経由）のみ許可する
  # 403にするとCloudFrontのcustom_error_response（S3の403をSPAにリダイレクトする設定）と競合するため400を使用
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "400"
    }
  }
}

resource "aws_lb_listener_rule" "cloudfront_only" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  condition {
    http_header {
      http_header_name = "X-Custom-Header"
      values           = [random_password.cloudfront_secret.result]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# CloudFront→ALB間の認証に使うシークレット
resource "random_password" "cloudfront_secret" {
  length  = 32
  special = false
}

# Route53 Aレコード: api.<domain> → ALB
resource "aws_route53_record" "alb" {
  zone_id = var.zone_id
  name    = var.api_domain
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
