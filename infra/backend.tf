terraform {
  backend "s3" {
    bucket         = "rcgrafbucket"
    dynamodb_table = "rcgraf-terraform-state"
    encrypt        = true
    key            = "projects/demurl/terraform-states-core.tfstate"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}
