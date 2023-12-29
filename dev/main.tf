provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = "${var.dev_prefix}"
      Service     = "webapp"
    }
  }
}

resource "random_pet" "petname" {
  length    = 3
  separator = "-"
}

resource "aws_s3_bucket" "dev" {
  bucket = "${var.dev_prefix}-${random_pet.petname.id}"

  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "dev" {
  bucket = aws_s3_bucket.dev.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "dev" {
  bucket = aws_s3_bucket.dev.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "dev" {
  bucket = aws_s3_bucket.dev.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "dev" {
  depends_on = [
    aws_s3_bucket_ownership_controls.dev,
    aws_s3_bucket_public_access_block.dev,
  ]

  bucket = aws_s3_bucket.dev.id

  acl = "public-read"
}

resource "aws_s3_bucket_policy" "dev" {
  depends_on = [
    aws_s3_bucket_acl.dev
  ]

  bucket = aws_s3_bucket.dev.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.dev.id}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_s3_object" "dev" {
  key          = "index.html"
  bucket       = aws_s3_bucket.dev.id
  content      = file("${path.module}/assets/index.html")
  content_type = "text/html"
}

resource "random_pet" "table_name" {}

resource "aws_dynamodb_table" "table" {
  name = "${var.dev_prefix}-${random_pet.table_name.id}"

  read_capacity  = var.db_read_capacity
  write_capacity = var.db_write_capacity
  hash_key       = "UUID"

  attribute {
    name = "UUID"
    type = "S"
  }
}

resource "aws_iam_role" "webapp_role" {
  name = "${var.dev_prefix}-webapp-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "webapp_attachment" {
  role       = aws_iam_role.webapp_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "webapp_profile" {
  name = "${var.dev_prefix}-webapp-profile"
  role = aws_iam_role.webapp_role.name
}

resource "aws_instance" "webapp_instance" {
  ami           = "ami-06ca3ca175f37dd66"
  instance_type = "t2.micro"
  
  iam_instance_profile = aws_iam_instance_profile.webapp_profile.name

  tags = {
    Name = "webapp-instance"
  }
}

resource "aws_s3_bucket_policy" "webapp_bucket_policy" {
  bucket = "gnehal-${var.dev_prefix}-webapp-bucket"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.webapp_role.name}"
        },
        "Action": [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "arn:aws:s3:::gnehal-${var.dev_prefix}-webapp-bucket",
          "arn:aws:s3:::gnehal-${var.dev_prefix}-webapp-bucket/*"
        ]
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
