data "aws_ssm_parameter" "al2023_ami" {
  # 最新のAmazon Linux 2023 AMI（ARM）を動的に取得
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

# ── Security Group ──────────────────────────────────────────────────────────────

resource "aws_security_group" "bastion" {
  name   = "${var.app_name}-bastion"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rds_from_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group_id
  source_security_group_id = aws_security_group.bastion.id
  description              = "Allow bastion to connect to RDS"
}

# ── IAM ────────────────────────────────────────────────────────────────────────

resource "aws_iam_role" "bastion" {
  name = "${var.app_name}-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "bastion_secretsmanager" {
  name = "secretsmanager"
  role = aws_iam_role.bastion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = var.admin_secret_arn
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:PutSecretValue"]
        Resource = var.app_secret_arn
      },
    ]
  })
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.app_name}-bastion"
  role = aws_iam_role.bastion.name
}

# ── EC2 ────────────────────────────────────────────────────────────────────────

resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = "t4g.nano"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y postgresql15 jq
  EOF

  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required" # IMDSv2
  }
}
