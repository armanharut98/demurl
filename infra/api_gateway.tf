resource "aws_api_gateway_rest_api" "demurl_api" {
  name        = "demurl_api"
  description = "demURL API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

// GET
resource "aws_api_gateway_resource" "get_id" {
  rest_api_id = aws_api_gateway_rest_api.demurl_api.id
  parent_id   = aws_api_gateway_rest_api.demurl_api.root_resource_id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.demurl_api.id
  resource_id   = aws_api_gateway_resource.get_id.id
  authorization = "NONE"
  http_method   = "GET"
}

resource "aws_api_gateway_integration" "get_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.demurl_api.id
  http_method             = aws_api_gateway_method.get.http_method
  resource_id             = aws_api_gateway_resource.get_id.id
  uri                     = aws_lambda_function.get_lambda.invoke_arn
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
}

resource "aws_lambda_permission" "apigw_get_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.demurl_api.execution_arn}/*/*/*"
}

// POST
resource "aws_api_gateway_resource" "shorten" {
  rest_api_id = aws_api_gateway_rest_api.demurl_api.id
  parent_id   = aws_api_gateway_rest_api.demurl_api.root_resource_id
  path_part   = "shorten"
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.demurl_api.id
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.shorten.id
}

resource "aws_api_gateway_integration" "post_lambda_integration" {
  http_method             = aws_api_gateway_method.post.http_method
  rest_api_id             = aws_api_gateway_rest_api.demurl_api.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  resource_id             = aws_api_gateway_resource.shorten.id
  uri                     = aws_lambda_function.post_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_post_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.demurl_api.execution_arn}/*/*/*"
}

// OPTIONS
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.demurl_api.id
  resource_id   = aws_api_gateway_resource.shorten.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.demurl_api.id
  resource_id             = aws_api_gateway_resource.shorten.id
  http_method             = aws_api_gateway_method.options.http_method
  integration_http_method = "OPTIONS"
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.demurl_api.id
  resource_id = aws_api_gateway_resource.shorten.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.demurl_api.id
  resource_id = aws_api_gateway_resource.shorten.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.options,
    aws_api_gateway_integration.options_integration,
  ]
}

resource "aws_api_gateway_deployment" "dev_deployment" {
  rest_api_id = aws_api_gateway_rest_api.demurl_api.id
  lifecycle {
    replace_triggered_by = [
      aws_api_gateway_integration.post_lambda_integration,
      aws_api_gateway_integration.get_lambda_integration
    ]
  }
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.dev_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.demurl_api.id
  stage_name    = "dev"
  lifecycle {
    replace_triggered_by = [aws_api_gateway_deployment.dev_deployment]
  }
}
