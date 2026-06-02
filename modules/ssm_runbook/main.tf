resource "aws_ssm_document" "rds_user_creation" {
  name            = "${var.app_name}-rds-user-creation"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/templates/rds_user_creation.yaml", {
    instance_id     = var.instance_id
    admin_secret_id = var.admin_secret_id
    rds_endpoint    = aws_db_instance.main.address
    db_name         = var.db_name
    app_secret_id   = var.app_secret_id
  })
}
