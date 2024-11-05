provider "aws" {
  region = "us-east-1"
}

# DynamoDB Table for schedules
resource "aws_dynamodb_table" "schedule_table" {
  name           = "InstanceSchedulerTable"
  hash_key       = "schedule_id"
  billing_mode   = "PAY_PER_REQUEST"

  attribute {
    name = "schedule_id"
    type = "S"
  }

  attribute {
    name = "start_hour"
    type = "N"
  }

  attribute {
    name = "stop_hour"
    type = "N"
  }

  attribute {
    name = "instance_ids"
    type = "SS" # String Set to hold instance IDs
  }
}

# IAM Role for Lambda function
resource "aws_iam_role" "lambda_exec_role" {
  name = "instance-scheduler-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda to access EC2 and DynamoDB
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "instance-scheduler-policy"
  role   = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:Scan",
          "dynamodb:GetItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.schedule_table.arn
      },
      {
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "instance_scheduler" {
  filename         = "lambda_function.zip"
  function_name    = "InstanceSchedulerFunction"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 60
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.schedule_table.name
    }
  }
}

# CloudWatch Event Rule to trigger Lambda every hour
resource "aws_cloudwatch_event_rule" "every_hour" {
  name        = "EveryHourSchedule"
  schedule_expression = "rate(1 hour)"
}

# Permission to allow CloudWatch Events to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.instance_scheduler.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_hour.arn
}

# CloudWatch Event Target for Lambda
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.every_hour.name
  target_id = "InstanceSchedulerLambda"
  arn       = aws_lambda_function.instance_scheduler.arn
}

# Zip Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}
