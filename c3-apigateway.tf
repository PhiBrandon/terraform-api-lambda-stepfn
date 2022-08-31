data "template_file" "name" {
  template = file("openapi.json")
  vars = {
    lambdaARN        = aws_lambda_function.terralambda.arn
    stepfnARN        = aws_sfn_state_machine.sfn_state_machine.arn
    executionRoleARN = aws_iam_role.iam_for_apigateway.arn
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

resource "aws_iam_role" "iam_for_apigateway" {
  name = "iam_for_apigateway"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "policy_for_apigateway" {
  name        = "api_iam_policy"
  description = "Policy that allows execution of step function state machine."
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "states:StartExecution",
        "states:StartSyncExecution"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_stepfn_apigateway" {
  role       = aws_iam_role.iam_for_apigateway.name
  policy_arn = aws_iam_policy.policy_for_apigateway.arn
}




