output "sqs_arn" {
  value     = aws_sqs_queue.s3_event_process_queue.arn
  sensitive = true
}