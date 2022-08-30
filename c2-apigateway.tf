resource "aws_api_gateway_rest_api" "template_rest_api" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "example"
      version = "1.0"
    }
    paths = {
      "/path1" = {
        get = {
          x-amazon-apigateway-integration = {
            "$ref" = "#/components/x-amazon-apigateway-integration/integration1"
          }
        }
      }
    },
    components: {
      x-amazon-apigateway-integrations:{
          "integration1": {
              "type": "aws",
              "httpMethod": "POST",
              "uri": "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:ACCOUNTNUMBER:function:my-function/invocations",
              "passthroughBehavior": "when_no_templates",
              "payloadFormatVersion": "1.0"
            },
          "integration2": {
              "type": "aws",
              "httpMethod": "POST",
              "uri": "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:ACCOUNTNUMBER:function:my-function/invocations",
              "passthroughBehavior": "when_no_templates",
              "payloadFormatVersion" : "1.0"
            }
        }
    }
  })

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