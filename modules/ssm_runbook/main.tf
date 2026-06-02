resource "aws_ssm_document" "rds_user_creation" {
  name            = "${var.app_name}-rds-user-creation"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/templates/rds_user_creation.yaml", {
    instance_id      = var.instance_id
    admin_secret_arn = var.admin_secret_arn
    rds_endpoint     = var.rds_endpoint
    db_name          = var.db_name
    app_secret_arn   = var.app_secret_arn
  })
}

