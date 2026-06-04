data "aws_caller_identity" "current" {}

data "aws_ecs_task_definition" "backend" {
  # アプリのCICDで更新したタスク定義を参照する
  task_definition = "${var.app_name}-backend"
}

resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"
}

resource "aws_ecs_service" "backend" {
  name            = "${var.app_name}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = data.aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group
    container_name   = "backend"
    container_port   = 3001
  }
}

resource "aws_ssm_parameter" "news_api_key" {
  name  = "/${var.app_name}/app/news_api_key"
  type  = "SecureString"
  value = "PLACEHOLDER" # 初回のみ。以後は手動で更新

  lifecycle {
    ignore_changes = [value] # Terraformが上書きしないようにする
  }
}

# IAM ロール（省略 - 実際には適切なポリシーを付与）
resource "aws_iam_role" "ecs_exec" {
  name               = "${var.app_name}-ecs-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.app_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ecs_exec_base" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_exec_base" {
  role       = aws_iam_role.ecs_exec.name
  policy_arn = data.aws_iam_policy.ecs_exec_base.arn
}

data "aws_iam_policy_document" "secrets_access" {
  statement {
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.db_app_credentials_secret_arn,
      var.cognito_client_secret_arn,
    ]
  }
  statement {
    actions = ["ssm:GetParameters"]
    resources = [
      aws_ssm_parameter.news_api_key.arn,
      var.db_name_param_arn,
      var.db_host_param_arn,
      var.cognito_user_pool_id_param_arn,
      var.cognito_client_id_param_arn,
      var.cognito_domain_param_arn,
      var.cognito_redirect_uri_param_arn,
      var.frontend_url_param_arn,
    ]
  }
  # SSMはKMSによる復号も必要
  statement {
    actions   = ["kms:Decrypt"]
    resources = ["arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"]
  }
}

resource "aws_iam_policy" "secrets_access" {
  name   = "${var.app_name}-secrets-access"
  policy = data.aws_iam_policy_document.secrets_access.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_secrets" {
  role       = aws_iam_role.ecs_exec.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

data "aws_iam_policy_document" "bedrock_invoke" {
  statement {
    sid    = "AllowBedrockInvoke"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    resources = [
      "arn:aws:bedrock:*::foundation-model/anthropic.claude-sonnet-4-6",
      "arn:aws:bedrock:*::inference-profile/us.anthropic.claude-sonnet-4-6",
      "arn:aws:bedrock:*:*:inference-profile/global.anthropic.claude-sonnet-4-6",
    ]
  }
}

resource "aws_iam_policy" "bedrock_invoke" {
  name   = "${var.app_name}-bedrock-invoke"
  policy = data.aws_iam_policy_document.bedrock_invoke.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_bedrock" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.bedrock_invoke.arn
}

