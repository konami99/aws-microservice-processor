output "sqs_arn" {
  value     = data.aws_ssm_parameter.sqs_arn.value
  sensitive = true
}