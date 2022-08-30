data "template_file" "name" {
  template = file("openapi.json")
  vars = {
    lambdaARN = aws_lambda_function.terralambda.arn
  }
}

resource "aws_api_gateway_rest_api" "template_rest_api" {

  body = data.template_file.name.rendered
  name = "template"

}

resource "aws_api_gateway_deployment" "template_deployment" {
  rest_api_id = aws_api_gateway_rest_api.template_rest_api.id


  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.template_rest_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "template_stage" {
  deployment_id = aws_api_gateway_deployment.template_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.template_rest_api.id
  stage_name    = "example"
}


// Define Lambda function
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

resource "aws_lambda_function" "terralambda" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename      = "function.zip"
  function_name = "test_function_terra"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("function.zip")

  runtime = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

// Define Step function
resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.iam_for_lambda.arn

  definition = <<EOF
{
  "Comment": "A Hello World example of the Amazon States Language using an AWS Lambda Function",
  "StartAt": "HelloWorld",
  "States": {
    "HelloWorld": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.terralambda.arn}",
      "End": true
    }
  }
}
EOF
}
