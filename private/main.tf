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

resource "aws_s3_object" "hello_world" {
  bucket       = aws_s3_bucket.private_bucket.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<-EOF
    <!DOCTYPE html>
    <html>
      <head>
        <title>Hello, World!</title>
      </head>
      <body>
        <h1>Hello, World!</h1>
      </body>
    </html>
  EOF
}

resource "aws_s3_object" "login_config" {
  bucket       = aws_s3_bucket.private_bucket.id
  key          = "login_config.json"
  content_type = "application/json"
  content      = jsonencode({ enabled = var.login_enabled })
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for accessing S3 bucket"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.private_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.oai.id}"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.private_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name = aws_s3_bucket.private_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.private_bucket.bucket

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.private_bucket.bucket

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.basic_auth.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

variable "private_cloudfront_password" {
  type = string
  # environment variable TF_VAR_private_cloudfront_password
}

variable "login_enabled" {
  type    = bool
  default = true
}

locals {
  basic_auth = base64encode("umihico:${var.private_cloudfront_password}")
  # echo -n umihico:password1234 | base64
}

resource "aws_cloudfront_function" "basic_auth" {
  name    = "basic-auth"
  runtime = "cloudfront-js-1.0"
  comment = "https://dev.classmethod.jp/articles/apply-basic-authentication-password-with-cloudfront-functions/"
  publish = true
  code    = <<CODE
function handler(event) {
  var request = event.request;
  var headers = request.headers;

  var authString = "Basic ${local.basic_auth}";

  if (typeof headers.authorization === "undefined" || headers.authorization.value !== authString) {
    return {
      statusCode: 401,
      statusDescription: "Unauthorized",
      headers: { "www-authenticate": { value: "Basic" } }
    };
  }

  return request;
}
CODE
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.website_distribution.domain_name
}

variable "rdp_password" { type = string } # TF_VAR_rdp_password
variable "instance_names" {
  type    = string
  default = ""
}
module "kabustation" {
  source         = "./kabustation"
  rdp_password   = var.rdp_password
  instance_names = var.instance_names
}
