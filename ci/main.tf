# terraform -chdir=ci apply

terraform {
  backend "s3" {
    bucket         = "kabu-json-terraform-states"
    key            = "ci/terraform.tfstate"
    dynamodb_table = "kabu-json-terraform-states-locker"
    region         = "ap-northeast-1"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "github_actions" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

// 定義済をimportするパターン
# import {
#   to = aws_iam_openid_connect_provider.github_actions
#   id = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
# }
# resource "aws_iam_openid_connect_provider" "github_actions" {
#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd", ]
# }

resource "aws_iam_role" "github_actions" {
  name = "kabu-json-github-actions-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github_actions.arn
      }
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:umihico/kabu-json-*"
          ]
        }
      }
    }]
  })
}

data "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "kabu-json-public-static-data-bucket"
}

data "aws_s3_bucket" "private_bucket" {
  bucket = "kabu-json-private-static-data-bucket"
}

resource "aws_iam_policy" "github_actions" {
  name        = "kabu-json-github-actions-policy"
  description = "Policy for kabu-json-github-actions-role"
  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect   = "Allow"
      Action   = "s3:PutObject"
      Resource = "${data.aws_s3_bucket.terraform_state_bucket.arn}/*"
      }, {
      Effect   = "Allow"
      Action   = "s3:PutObject"
      Resource = "${data.aws_s3_bucket.private_bucket.arn}/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
