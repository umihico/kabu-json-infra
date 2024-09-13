

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

// gitに含めれないローカルのterraform.tfstateをロストしても良いように
import {
  to = aws_s3_bucket.terraform_state_bucket
  id = "kabu-json-terraform-states"
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "kabu-json-terraform-states"

  tags = {
    Name = "Terraform State Bucket"
  }
}

// gitに含めれないローカルのterraform.tfstateをロストしても良いように
import {
  to = aws_s3_bucket_public_access_block.terraform_state_bucket_public_access_block
  id = "kabu-json-terraform-states"
}

resource "aws_s3_bucket_public_access_block" "terraform_state_bucket_public_access_block" {
  bucket = aws_s3_bucket.terraform_state_bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// gitに含めれないローカルのterraform.tfstateをロストしても良いように
import {
  to = aws_dynamodb_table.terraform_locker_table
  id = "kabu-json-terraform-states-locker"
}

resource "aws_dynamodb_table" "terraform_locker_table" {
  name         = "kabu-json-terraform-states-locker"
  hash_key     = "LockID"
  billing_mode = "PROVISIONED"

  attribute {
    name = "LockID"
    type = "S"
  }

  // 無料枠が25あるので、実際は課金されない
  read_capacity  = 1
  write_capacity = 1

  tags = {
    Name = "kabu-json-terraform-states-locker"
  }
}
