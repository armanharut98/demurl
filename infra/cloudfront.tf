resource "aws_cloudfront_origin_access_identity" "vite_oai" {}

# Create an S3 bucket
resource "aws_s3_bucket" "vite_app" {
  bucket = "rcgraf-vite-app-bucket"
}

# Configure S3 bucket for static hosting
resource "aws_s3_bucket_website_configuration" "vite_website" {
  bucket = aws_s3_bucket.vite_app.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Set bucket policy for public read access (if needed)
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.vite_app.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.vite_app.arn}/*"
    }]
  })
}

resource "aws_s3_object" "vite_files" {
  for_each = fileset("../frontend/dist", "**/*")
  bucket   = aws_s3_bucket.vite_app.id
  key      = each.value
  source   = "../frontend/dist/${each.value}"
  etag     = filemd5("../frontend/dist/${each.value}")
  content_type = lookup({
    "html"  = "text/html",
    "js"    = "application/javascript",
    "css"   = "text/css",
    "json"  = "application/json",
    "png"   = "image/png",
    "jpg"   = "image/jpeg",
    "svg"   = "image/svg+xml"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

resource "aws_cloudfront_origin_access_control" "vite_oac" {
  name                              = "vite-app-cloudfront-oac"
  description                       = "OAC for CloudFront to access S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                   = "sigv4"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "demurl.com"
  validation_method = "DNS"
}

resource "aws_cloudfront_distribution" "vite_distribution" {
  depends_on = [aws_s3_bucket.vite_app]

  origin {
    domain_name              = aws_s3_bucket.vite_app.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.vite_oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  aliases = ["demurl.com"]

   viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

    restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront_access" {
  bucket = aws_s3_bucket.vite_app.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "cloudfront.amazonaws.com"
      },
      Action = "s3:GetObject",
      Resource = "${aws_s3_bucket.vite_app.arn}/*",
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.vite_distribution.arn
        }
      }
    }]
  })
}

resource "aws_route53_record" "cloudfront_alias" {
  zone_id = "Z09665903I1B66USIWRIP"
  name    = "demurl.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.vite_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.vite_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
