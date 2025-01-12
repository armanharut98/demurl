terraform {
  backend "s3" {
    bucket         = "aca-infra-states"
    key            = "tf-projects/demurl.tfstate"
    dynamodb_table = "aca-infra-state-lock"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}
