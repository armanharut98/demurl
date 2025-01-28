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

resource "aws_api_gateway_deployment" "dev_deployment" {
  depends_on = [
    aws_api_gateway_integration.post_lambda_integration,
    aws_api_gateway_integration.get_lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.demurl_api.id
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.dev_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.demurl_api.id
  stage_name    = "dev"
}
