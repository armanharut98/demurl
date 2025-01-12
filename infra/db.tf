resource "aws_dynamodb_table" "main" {
  name           = "demurl"
  billing_mode   = "PROVISIONED"
  read_capacity  = 25
  write_capacity = 25
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
