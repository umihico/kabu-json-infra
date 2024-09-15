# terraform -chdir=private apply

terraform {
  backend "s3" {
    bucket         = "kabu-json-terraform-states"
    key            = "private/terraform.tfstate"
    dynamodb_table = "kabu-json-terraform-states-locker"
    region         = "ap-northeast-1"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_s3_bucket" "private_bucket" {
  bucket = "kabu-json-private-static-data-bucket"
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.private_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
