# ── ECR ────────────────────────────────────────────────────────────────────────

resource "aws_ecr_repository" "migration" {
  name                 = "${var.app_name}-migration"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "migration" {
  repository = aws_ecr_repository.migration.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "untaggedイメージを1日後に削除"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "直近10件を超えたtaggedイメージを削除"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

# ── Security Group ──────────────────────────────────────────────────────────────

resource "aws_security_group" "migration" {
  name   = "${var.app_name}-migration"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rds_from_migration" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group_id
  source_security_group_id = aws_security_group.migration.id
  description              = "Allow DB migration task to connect"
}

# ── IAM ────────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "migration_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "migration_exec" {
  name               = "${var.app_name}-migration-exec"
  assume_role_policy = data.aws_iam_policy_document.migration_assume.json
}

resource "aws_iam_role" "migration_task" {
  name               = "${var.app_name}-migration-task"
  assume_role_policy = data.aws_iam_policy_document.migration_assume.json
}

data "aws_iam_policy" "ecs_exec_base" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "migration_exec_base" {
  role       = aws_iam_role.migration_exec.name
  policy_arn = data.aws_iam_policy.ecs_exec_base.arn
}

data "aws_iam_policy_document" "migration_secrets_access" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_app_credentials_secret_arn]
  }
  statement {
    actions = ["ssm:GetParameters"]
    resources = [
      var.db_host_param_arn,
      var.db_name_param_arn,
    ]
  }
}

resource "aws_iam_policy" "migration_secrets_access" {
  name   = "${var.app_name}-migration-secrets-access"
  policy = data.aws_iam_policy_document.migration_secrets_access.json
}

resource "aws_iam_role_policy_attachment" "migration_exec_secrets" {
  role       = aws_iam_role.migration_exec.name
  policy_arn = aws_iam_policy.migration_secrets_access.arn
}

# ── CloudWatch Logs ─────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "migration" {
  name              = "/ecs/${var.app_name}-migration"
  retention_in_days = 30
}

# ── ECS ────────────────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "migration" {
  name = "${var.app_name}-migration-cluster"
}

resource "aws_ecs_task_definition" "migration" {
  family                   = "${var.app_name}-migration"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.migration_exec.arn
  task_role_arn            = aws_iam_role.migration_task.arn

  container_definitions = jsonencode([{
    name      = "migration"
    image     = "${aws_ecr_repository.migration.repository_url}:latest"
    essential = true

    environment = [
      { name = "DB_SSL", value = "true" }
    ]

    secrets = [
      { name = "DB_HOST", valueFrom = var.db_host_param_arn },
      { name = "DB_NAME", valueFrom = var.db_name_param_arn },
      { name = "DB_USER", valueFrom = "${var.db_app_credentials_secret_arn}:username::" },
      { name = "DB_PASSWORD", valueFrom = "${var.db_app_credentials_secret_arn}:password::" },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.migration.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "migration"
      }
    }
  }])

  lifecycle {
    ignore_changes = [container_definitions]
  }
}
