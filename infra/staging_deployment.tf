locals {
  common_tags = {
    env     = terraform.workspace
    owner   = "richard chou"
    project = "aws-microservice-processor"
  }
}

terraform {
  backend "s3" {
    bucket = "aws-microservice-processor"
    key    = "state"
    region = "us-west-2"
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_sqs_queue" "s3_event_process_queue" {
  name   = "s3-event-process-queue"
  policy = data.aws_iam_policy_document.sqs-queue-policy.json

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "sqs_target" {
  topic_arn = data.aws_ssm_parameter.sns_arn.value
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.s3_event_process_queue.arn
}

data "aws_ssm_parameter" "sns_arn" {
  name = "sns_arn"
}

data "aws_iam_policy_document" "sqs-queue-policy" {
  statement {
    sid    = "sns-topic"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "SQS:SendMessage",
    ]

    resources = [
      aws_sqs_queue.s3_event_process_queue.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        data.aws_ssm_parameter.sns_arn.value,
      ]
    }
  }
}