provider "aws" {
  region = "us-east-2"
}

//dynamoDB Code: Table name "pollinate" with partition key "date_time"

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "pollinate_tf"
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "date_time_tf"

  attribute {
    name = "date_time_tf"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "dev"
  }
}

// AWS IAM Role for Lambda

resource "aws_iam_role" "lambda_role" {
  name               = "terraform_aws_lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


# IAM policy for logging from a lambda

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

// IAM Policy for DyanomoDB

resource "aws_iam_policy" "iam_policy_for_dynamodb" {

  name        = "aws_iam_policy_for_terraform_aws_dynamodb_role"
  path        = "/"
  description = "AWS IAM Policy for managing aws dynamodb role"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1666059204349",
      "Action": [
        "dynamodb:CreateBackup",
        "dynamodb:CreateTable",
        "dynamodb:PutItem"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# Logging Policy Attachment on the role.

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn

}

# DynamoDB Policy Attachment on the role.

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role_dynamo" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_dynamodb.arn

}


# Generates an archive from content, a file, or a directory of files.

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/python/hello-python.zip"
}

data "archive_file" "zip_the_backup_code" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/python/backup.zip"
}

# Create a lambda function
# In terraform ${path.module} is the current directory.
resource "aws_lambda_function" "terraform_lambda_func" {
  filename      = "${path.module}/python/hello-python.zip"
  function_name = "terraform_datetime_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "hello-python.lambda_handler"
  runtime       = "python3.9"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role_dynamo]
}

# Create a lambda function
# In terraform ${path.module} is the current directory.
resource "aws_lambda_function" "terraform_lambda_backup" {
  filename      = "${path.module}/python/backup.zip"
  function_name = "terraform_backup_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "backup.lambda_handler"
  runtime       = "python3.9"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

// Creating API Gateway

resource "aws_apigatewayv2_api" "lambda-api" {
  name          = "datetimetf"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda-stage" {
  api_id      = aws_apigatewayv2_api.lambda-api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda-integration" {
  api_id               = aws_apigatewayv2_api.lambda-api.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.terraform_lambda_func.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda-api.id
  route_key = "POST /apigwtf"
  target    = "integrations/${aws_apigatewayv2_integration.lambda-integration.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda-api.execution_arn}/*/*/*"
}


