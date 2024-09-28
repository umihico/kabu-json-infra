# https://checkip.amazonaws.com/

resource "aws_cloudfront_function" "proxy" {
  name    = "return-client-ip-and-headers"
  runtime = "cloudfront-js-1.0"

  code = <<EOF
function handler(event) {
    var request = event.request;
    var response = {
        statusCode: 200,
        statusDescription: 'OK',
        headers: {
            'content-type': { value: 'application/json' },
            'access-control-allow-origin': { value: '*' }
        },
        body: JSON.stringify({
            headers: request.headers,
            message: 'Proxy reached! Date:' + new Date().valueOf(),
            ip: event.viewer.ip
        })
    };
    return response;
}
EOF
}

resource "aws_cloudfront_distribution" "proxy" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution with function to test proxy"
  default_root_object = ""

  default_cache_behavior {
    target_origin_id       = "no-use-origin"
    viewer_protocol_policy = "allow-all"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.proxy.arn
    }

    cached_methods  = ["GET", "HEAD", "OPTIONS"]
    allowed_methods = ["GET", "HEAD", "OPTIONS"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    default_ttl = 0
    min_ttl     = 0
    max_ttl     = 0
  }

  # Since you don't want an origin, we define a dummy origin to satisfy the distribution requirements.
  origin {
    domain_name = "example.com"
    origin_id   = "no-use-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  price_class = "PriceClass_All"
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "proxy_domain_name" {
  value = aws_cloudfront_distribution.proxy.domain_name
}
