output "cloudfront_endpoint" {
  value       = aws_cloudfront_distribution.default.domain_name
  description = "The CloudFront distribution endpoint"
}

output "bucket_name" {
  value = var.bucket_name
  description = "name of the web hosting bucket"
}