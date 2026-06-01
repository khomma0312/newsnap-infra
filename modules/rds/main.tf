terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
    }
  }
}

resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "db_admin_credentials" {
  name                    = "/${var.app_name}/db/admin_credentials"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_admin_credentials" {
  secret_id     = aws_secretsmanager_secret.db_admin_credentials.id
  secret_string = jsonencode({ username = var.db_admin_user, password = random_password.db.result })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.app_name}/db/db_name"
  type  = "String"
  value = var.db_name
}

resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.app_name}/db/db_host"
  type  = "String"
  value = aws_db_instance.main.address
}

resource "aws_secretsmanager_secret" "db_app_credentials" {
  name                    = "/${var.app_name}/db/app_credentials"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_app_credentials" {
  secret_id     = aws_secretsmanager_secret.db_app_credentials.id
  secret_string = jsonencode({ username = "PLACEHOLDER", password = "PLACEHOLDER" })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-db-subnet"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "main" {
  identifier        = "${var.app_name}-db"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_admin_user
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]

  skip_final_snapshot = true
  multi_az            = false

  lifecycle {
    # パスワードを手動ローテーションした場合にTerraformが元に戻さないようにする
    ignore_changes = [password]
  }
}
