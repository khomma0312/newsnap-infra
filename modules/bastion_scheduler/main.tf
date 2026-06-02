resource "aws_iam_role" "bastion_stop_scheduler" {
  name = "${var.app_name}-bastion-stop-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "bastion_stop" {
  name = "ec2-stop"
  role = aws_iam_role.bastion_stop_scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ec2:StopInstances"
      Resource = "arn:aws:ec2:*:*:instance/${var.bastion_instance_id}"
    }]
  })
}

resource "aws_scheduler_schedule" "bastion_stop_daily" {
  name       = "${var.app_name}-bastion-stop-daily"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.bastion_stop_scheduler.arn

    input = jsonencode({
      InstanceIds = [var.bastion_instance_id]
    })
  }
}
