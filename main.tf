terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}


//dynamoDB Code: Table name "pollinate" with partition key "date_time"

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "pollinate1"
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  hash_key = "date_time"

  attribute {
    name = "date_time"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}



//Creating Lambda function

data "archive_file" "lambda-zip" {
  type = "zip"
  source_dir = "/lambda.py"
  output_path = "/lambda.zip"
}


// IAM Role for lambda Function

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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


resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = "lambda"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda.lambda_handler"
  source_code_hash = data.archive_file.lambda-zip.output_base64sha256
  runtime       = "python3.9"

}

// Creating API Gateway

resource "aws_apigatewayv2_api" "lambda-api" {
  name          = "example-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda-stage" {
  api_id = aws_apigatewayv2_api.lambda-api.id
  name   = "$default"
  auto_deploy = true
}


resource "aws_apigatewayv2_integration" "lambda-integration" {
  api_id           = aws_apigatewayv2_api.lambda-api.id
  integration_type = "AWS_PROXY"
  integration_method        = "POST"
  integration_uri           = aws_lambda_function.lambda.invoke_arn
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda-api.id
  route_key = "POST /{proxy+}"
  target = "integrations/${aws_apigatewayv2_integration.lambda-integration.id}"
}

resource "aws_lambda_permission" "api_gw" {
    statement_id = "AllowExecutionFromAPIGateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda.arn
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.lambda-api.execution_arn}/*/*/*"

  
}