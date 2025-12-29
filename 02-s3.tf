resource "aws_s3_bucket" "bucket" {
  bucket = "gbsw-s3-bucket-${var.number}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.bucket.arn}/log/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_object" "log_folder" {
  bucket = aws_s3_bucket.bucket.bucket
  key = "log/"
}

resource "aws_s3_bucket_object" "image_folder" {
  bucket = aws_s3_bucket.bucket.bucket
  key = "image/"
}

resource "aws_s3_object" "product" {
  bucket = aws_s3_bucket.bucket.bucket
  key    = "image/product/product"
  source = "./src/product"
  etag   = filemd5("./src/product")
}

resource "aws_s3_object" "dockerfile" {
  bucket = aws_s3_bucket.bucket.bucket
  key    = "image/product/Dockerfile"
  source = "./src/Dockerfile"
  etag   = filemd5("./src/Dockerfile")
}