provider "aws" {
  region = "us-east-1"
}

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
      Effect = "Allow",
      Principal = "*",
      Action = "s3:GetObject",
      Resource = "${aws_s3_bucket.vite_app.arn}/*"
    }]
  })
}

resource "aws_s3_object" "vite_files" {
  for_each = fileset("../dist", "**/*")
  bucket   = aws_s3_bucket.vite_app.id
  key      = each.value
  source   = "../dist/${each.value}"
  etag     = filemd5("../dist/${each.value}")
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

resource "aws_cloudfront_distribution" "vite_distribution" {
  origin {
    domain_name = aws_s3_bucket.vite_app.bucket_regional_domain_name
    origin_id   = "vite-app-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.vite_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "vite-app-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100"
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "vite_oai" {}
