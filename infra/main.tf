locals {
  common_tags = {
    env     = terraform.workspace
    owner   = "richard chou"
    project = "aws-microservice-processor"
  }
}

terraform {
  backend "s3" {
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

data "aws_ssm_parameter" "sqs_arn" {
  name = "sqs_arn"
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
      data.aws_ssm_parameter.sqs_arn.value
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

resource "aws_dynamodb_table" "images" {
  name             = "images"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "timestamp"
  range_key        = "format"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "format"
    type = "S"
  }

  attribute {
    name = "filename"
    type = "S"
  }

  ttl {
    attribute_name = "time_to_exist"
    enabled        = false
  }

  local_secondary_index {
    name            = "filename_index"
    range_key       = "filename"
    projection_type = "ALL"
  }

  tags = local.common_tags
}

resource "aws_ssm_parameter" "dynamodb-stream-arn" {
  name      = "dynamodb_stream_arn"
  type      = "SecureString"
  value     = aws_dynamodb_table.images.stream_arn
  overwrite = true

  tags = local.common_tags
}