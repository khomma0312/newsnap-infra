terraform {
  required_version = "~> 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = var.backend_bucket_name
    key    = "newsnap/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

locals {
  app_name      = "prod-${var.app_name}"
  aws_region    = var.aws_region
  zone_domain   = var.zone_domain
  domain        = var.zone_domain
  api_domain    = "api.${var.zone_domain}"
  db_name       = var.db_name
  db_admin_user = var.db_admin_user
}

provider "aws" {
  region = local.aws_region

  default_tags {
    tags = {
      Environment = "prod"
      Application = "newsnap"
      ManagedBy   = "terraform"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "prod"
      Application = "newsnap"
      ManagedBy   = "terraform"
    }
  }
}

# ── VPC ──────────────────────────────────────────────────────────────────────

module "vpc" {
  source   = "../../modules/vpc"
  app_name = local.app_name
}

# ── DNS / ACM ────────────────────────────────────────────────────────────────

module "dns" {
  source = "../../modules/dns"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  zone_domain = local.zone_domain
  domain      = local.domain
}

# ── WAF（us-east-1, CloudFront用）─────────────────────────────────────────────

module "waf" {
  source = "../../modules/waf"

  providers = {
    aws = aws.us_east_1
  }

  app_name = local.app_name
}

# ── S3（フロントエンド静的アセット）─────────────────────────────────────────────

module "s3" {
  source   = "../../modules/s3"
  app_name = local.app_name
}

# ── ECR ──────────────────────────────────────────────────────────────────────

module "ecr" {
  source   = "../../modules/ecr"
  app_name = local.app_name
}

# ── ALB ──────────────────────────────────────────────────────────────────────

module "alb" {
  source = "../../modules/alb"

  app_name            = local.app_name
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_id   = module.vpc.alb_security_group_id
  acm_certificate_arn = module.dns.alb_cert_arn
  zone_id             = module.dns.zone_id
  api_domain          = local.api_domain
}

# ── Cognito ───────────────────────────────────────────────────────────────────

module "cognito" {
  source = "../../modules/cognito"

  app_name      = local.app_name
  callback_urls = ["https://${local.domain}/callback", "http://localhost:3000/callback"]
  logout_urls   = ["https://${local.domain}", "http://localhost:3000"]
}

# ── RDS ──────────────────────────────────────────────────────────────────────

module "rds" {
  source = "../../modules/rds"

  app_name          = local.app_name
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.vpc.rds_security_group_id
  db_name           = local.db_name
  db_admin_user     = local.db_admin_user
}

# ── Bastion ───────────────────────────────────────────────────────────────────

module "bastion" {
  source = "../../modules/bastion"

  app_name              = local.app_name
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[0]
  rds_security_group_id = module.vpc.rds_security_group_id
  admin_secret_arn      = module.rds.db_admin_credentials_secret_arn
  app_secret_arn        = module.rds.db_app_credentials_secret_arn
}

# ── SSM Runbook ───────────────────────────────────────────────────────────────

module "ssm_runbook" {
  source = "../../modules/ssm_runbook"

  app_name         = local.app_name
  instance_id      = module.bastion.instance_id
  admin_secret_arn = module.rds.db_admin_credentials_secret_arn
  app_secret_arn   = module.rds.db_app_credentials_secret_arn
  rds_endpoint     = module.rds.db_endpoint
  db_name          = local.db_name
}

# ── Bastion Stop Scheduler（毎日 23:00 JST に自動停止）──────────────────────────

module "bastion_scheduler" {
  source = "../../modules/bastion_scheduler"

  app_name            = local.app_name
  bastion_instance_id = module.bastion.instance_id
}

# ── ECS ──────────────────────────────────────────────────────────────────────

module "ecs" {
  source = "../../modules/ecs"

  app_name                       = local.app_name
  aws_region                     = local.aws_region
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnet_ids
  alb_target_group               = module.alb.target_group_arn
  db_host_param_arn              = module.rds.db_host_param_arn
  db_name_param_arn              = module.rds.db_name_param_arn
  db_app_credentials_secret_arn  = module.rds.db_app_credentials_secret_arn
  cognito_client_secret_arn      = module.cognito.client_secret_arn
  cognito_user_pool_id_param_arn = module.cognito.user_pool_id_param_arn
  cognito_client_id_param_arn    = module.cognito.client_id_param_arn
  cognito_domain_param_arn       = module.cognito.domain_param_arn
  cognito_redirect_uri_param_arn = module.cognito.redirect_uri_param_arn
  frontend_url_param_arn         = module.cognito.frontend_url_param_arn
  security_group_id              = module.vpc.ecs_security_group_id
}

# ── ECS Migration ────────────────────────────────────────────────────────────

module "ecs_migration" {
  source = "../../modules/ecs_migration"

  app_name                      = local.app_name
  aws_region                    = local.aws_region
  vpc_id                        = module.vpc.vpc_id
  rds_security_group_id         = module.vpc.rds_security_group_id
  db_host_param_arn             = module.rds.db_host_param_arn
  db_name_param_arn             = module.rds.db_name_param_arn
  db_app_credentials_secret_arn = module.rds.db_app_credentials_secret_arn
}

# ── CloudFront ────────────────────────────────────────────────────────────────

module "cloudfront" {
  source = "../../modules/cloudfront"

  app_name                       = local.app_name
  domains                        = [local.domain]
  acm_certificate_arn            = module.dns.cloudfront_cert_arn
  zone_id                        = module.dns.zone_id
  s3_bucket_id                   = module.s3.bucket_id
  s3_bucket_arn                  = module.s3.bucket_arn
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  alb_dns_name                   = module.alb.api_domain
  cloudfront_secret              = module.alb.cloudfront_secret
  web_acl_arn                    = module.waf.web_acl_arn
}
