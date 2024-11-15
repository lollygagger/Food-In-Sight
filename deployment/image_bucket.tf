resource "random_uuid" "bucket_uuid" {}

#Bucket to store images for rekognition
resource "aws_s3_bucket" "image_bucket" {
  bucket = "imagebucket-${random_uuid.bucket_uuid.result}"
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