data "aws_s3_object" "post_lambda" {
  bucket = "demurl"
  key    = "lambdas/post.zip"
}

data "aws_s3_object" "post_layer" {
  bucket = "demurl"
  key    = "lambdas/post-layer.zip"
}

data "aws_s3_object" "get_lambda" {
  bucket = "demurl"
  key    = "lambdas/get.zip"
}

data "aws_s3_object" "get_layer" {
  bucket = "demurl"
  key    = "lambdas/get-layer.zip"
}

resource "aws_lambda_layer_version" "post_layer" {
  layer_name          = "post_layer"
  s3_bucket           = "demurl"
  s3_key              = "lambdas/post-layer.zip"
  source_code_hash    = data.aws_s3_object.post_layer.etag
  compatible_runtimes = ["nodejs16.x"]
}

resource "aws_lambda_layer_version" "get_layer" {
  layer_name          = "get_layer"
  s3_bucket           = "demurl"
  s3_key              = "lambdas/get-layer.zip"
  source_code_hash    = data.aws_s3_object.get_layer.etag
  compatible_runtimes = ["nodejs16.x"]
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.main.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_exec_role"
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

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "post_lambda" {
  function_name    = "post_lambda"
  s3_bucket        = "demurl"
  s3_key           = data.aws_s3_object.post_lambda.key
  layers           = [aws_lambda_layer_version.post_layer.arn]
  role             = aws_iam_role.lambda_role.arn
  runtime          = "nodejs16.x"
  handler          = "post_lambda.handler"
  source_code_hash = data.aws_s3_object.post_lambda.etag
}

resource "aws_lambda_function" "get_lambda" {
  function_name    = "get_lambda"
  s3_bucket        = "demurl"
  s3_key           = data.aws_s3_object.get_lambda.key
  layers           = [aws_lambda_layer_version.get_layer.arn]
  role             = aws_iam_role.lambda_role.arn
  runtime          = "nodejs16.x"
  handler          = "get_lambda.handler"
  source_code_hash = data.aws_s3_object.get_lambda.etag
}
