output "schedule_arn" {
  value = aws_scheduler_schedule.rds_stop_weekly.arn
}
