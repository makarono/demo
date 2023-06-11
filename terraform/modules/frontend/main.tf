
resource "aws_s3_bucket" "default" {
  bucket        = var.bucket_name
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.default.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_website_configuration" "default" {
  bucket = aws_s3_bucket.default.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

resource "aws_cloudfront_origin_access_identity" "default" {
  comment = "S3 access identity for the fronted hosted on s3"
}

resource "aws_s3_bucket_policy" "default" {
  bucket = aws_s3_bucket.default.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.default.arn}/*"
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.default.id}"
        }
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "default" {
  comment = "frontend website cdn for the bucket: ${aws_s3_bucket.default.id}"
  origin {
    domain_name = aws_s3_bucket.default.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.default.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
    }
  }

  enabled = true
  #is_ipv6_enabled     = true
  default_root_object = var.index_document

  default_cache_behavior {
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["HEAD", "GET", "OPTIONS"]
    target_origin_id = "S3-${aws_s3_bucket.default.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  tags = var.tags
}

