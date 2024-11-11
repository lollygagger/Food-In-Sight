resource "aws_s3_bucket" "image_bucket" {
  bucket = "imagebucketuniquename123123089658970"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "image_bucket_controls" {
  bucket = aws_s3_bucket.image_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "image_bucket_ac1" {
  depends_on = [aws_s3_bucket_ownership_controls.image_bucket_controls]

  bucket = aws_s3_bucket.image_bucket.id
  acl    = "private"
}