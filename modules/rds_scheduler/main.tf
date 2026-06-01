resource "aws_iam_role" "rds_stop_scheduler" {
  name = "${var.app_name}-rds-stop-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "rds_stop" {
  name = "rds-stop"
  role = aws_iam_role.rds_stop_scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "rds:StopDBInstance"
      Resource = "arn:aws:rds:*:*:db:${var.db_instance_identifier}"
    }]
  })
}

resource "aws_scheduler_schedule" "rds_stop_weekly" {
  name       = "${var.app_name}-rds-stop-weekly"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
    role_arn = aws_iam_role.rds_stop_scheduler.arn

    input = jsonencode({
      DbInstanceIdentifier = var.db_instance_identifier
    })
  }
}
